# kemal-basic-auth

Add basic auth to your [Kemal](http://github.com/kemalcr/kemal) application.

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  kemal-basic-auth:
    github: kemalcr/kemal-basic-auth
```


## Usage


```crystal
require "kemal-basic-auth"

basic_auth "username", "password"
```


## Contributing

1. Fork it ( https://github.com/kemalcr/kemal-basic-auth/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [[your-github-name]](https://github.com/[your-github-name]) Serdar Dogruyol - creator, maintainer
