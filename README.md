# haproxy_graphite

haproxy stats to graphite

## configuration

### haproxy

````
listen stats 127.0.0.1:3084
  stats enable
  stats realm HAProxy\ Stats
  stats uri /stats
  stats auth admin:admin
````

### daemon

* see `config.yml_sample` and rename to `config.yml`
* do any necessary changes here

## start

* make `haproxy_graphite.daemon` executable with `chmod 755 ./haproxy_graphite.daemon`
* start with `./haproxy_graphite.daemon start`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright @ 2014 Tom Meinlschmidt. See [MIT-LICENSE](https://github.com/tmeinlschmidt/redis_graphite/blob/master/LICENSE) for details
