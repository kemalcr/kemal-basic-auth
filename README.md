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
require "kemal/basic_auth"

basic_auth "username", "password"
# basic_auth {"username1" => "password1", "username2" => "password2"}
```

### `kemal_authorized_username`

`HTTP::Server::Context#kemal_authorized_username?` is set when the user is authorized.

```crystal
basic_auth {"guest" => "123", "admin" => "xyz"}

get "/" do |env|
  "Hi, %s!" % env.kemal_authorized_username?
end
```

## Contributing

1. Fork it ( https://github.com/kemalcr/kemal-basic-auth/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [sdogruyol](https://github.com/sdogruyol) Serdar Dogruyol - creator, maintainer
