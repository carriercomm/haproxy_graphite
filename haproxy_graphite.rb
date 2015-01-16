#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require 'curb'
require 'yaml'
require 'ostruct'
require 'graphite-api'
require 'graphite-api/core_ext/numeric'

module ConfigFile

  def self.load_yaml(object)
    return case object
    when Hash
      object = object.clone
      object.each do |key, value|
      object[key] = load_yaml(value)
    end
    OpenStruct.new(object)
    when Array
      object = object.clone
      object.map! { |i| load_yaml(i) }
    else
      object
    end
  end

end

module Collector

  class Poll

    DICTIONARY = {
      'qcur' =>  'requests.current_queued',
      'qmax' =>  'requests.max_queued',
      'scur' =>  'sessions.current_sess',
      'smax' =>  'sessions.max_sess',
      'slim' =>  'sessions.limit_ses',
      'stot' =>  'sessions.total',
      'bin' =>  'bytes.b_in',
      'bout' =>  'bytes.b_out',
      'dreq' =>  'denied.requests',
      'dresp' =>  'denied.responses',
      'ereq' =>  'errors.request',
      'econ' =>  'errors.connection',
      'eresp' =>  'errors.response',
      'wretr' =>  'warning.retries',
      'wredis' =>  'warning.redispatches',
      'weight' =>  'server.weight',
      'act' =>  'server.is_active',
      'bck' =>  'server.is_backup',
      'chkfail' =>  'checks.failed',
      'chkdown' =>  'checks.transitions',
      'lastchg' =>  'checks.last_status_change',
      'downtime' =>  'check.total_downtime',
      'qlimit' =>  'queue.limit',
      'throttle' =>  'throttle',
      'lbtot' =>  'server.selected',
      'rate' =>  'rate.per_second',
      'rate_lim' =>  'rate.limit',
      'rate_max' =>  'rate.maximum',
      'check_code' =>  'checks.code',
      'check_duration' =>  'checks.duration',
      'hrsp_1xx' =>  'responses.1xx',
      'hrsp_2xx' =>  'responses.2xx',
      'hrsp_3xx' =>  'responses.3xx',
      'hrsp_4xx' =>  'responses.4xx',
      'hrsp_5xx' =>  'responses.5xx',
      'hrsp_other' =>  'responses.other',
      'hanafail' => 'checks.fail_detail',
      'req_rate' =>  'requests.rate',
      'req_rate_max' =>  'requests.max_rate',
      'req_tot' =>  'requests.total',
      'cli_abrt' =>  'aborted.client',
      'srv_abrt' =>  'aborted.server',
      'comp_in' => 'compression.b_in',
      'comp_out' => 'compression.b_out',
      'comp_rsp' => 'compression.responses',
      'comp_byp' => 'compression.bypassed',
      'qtime' => 'time.queue',
      'ctime' => 'time.connect',
      'rtime' => 'time.response',
      'ttime' => 'time.session_total'
    }

    def initialize
      settings = ConfigFile.load_yaml(
        YAML.load_file(File.dirname(Pathname.new(__FILE__).realpath)+'/config.yml'))

      haproxy = settings.haproxy
      raise 'Missing haproxy config' if haproxy.empty?

      graphite = settings.graphite
      raise 'Missing graphite config' if graphite.nil?

      params = { graphite: "#{graphite.host}:#{graphite.port}", prefix: [graphite.prefix]}

      @graphite = GraphiteAPI.new( params )
      c = @graphite

      Zscheduler.every(10) do
        begin

          ha = Curl::Easy.new("#{haproxy.stats_url};csv")

          # do we need authentication?
          if haproxy.credentials.username
            ha.http_auth_types = :basic
            ha.username = haproxy.credentials.username
            ha.password = haproxy.credentials.password
          end
          ha.perform

          data = ha.body_str.split("\n")
          headers = data.shift.split(',').map{ |s| s.gsub(/[# ]/,'') }
          new_data = data.map{|a| parse_line(headers, a) }

          # and report
          new_data.each do |line|
            prefix = "#{line['pxname']}.#{line['svname'].downcase}"
            line.each do |key, data|
              var = DICTIONARY[key]
              # skip as we don't need this value
              next unless var
              c.metrics("#{prefix}.#{var}" => data.to_i)
            end
          end
        rescue Exception => e
          raise "error #{e}"
        end
      end
      Zscheduler.join
    end

  private

  # add key->value pairs with data and headers
  def parse_line(headers = [], line)
    data = line.split(',')
    Hash[*headers.zip(data).flatten]
  end

  end

  service = Collector::Poll.new

end
