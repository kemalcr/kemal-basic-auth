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

#### Basic example

kemal-basic-auth adds authentication to all routes by default.

```crystal
require "kemal-basic-auth"

basic_auth "username", "password"
# basic_auth {"username1" => "password1", "username2" => "password2"}
```

#### Authentication for specific routes

`Kemal::BasicAuth::Handler` inherits from `Kemal::Handler` and it is therefore easy to create a custom handler that adds authentication to specific routes instead of all routes.

```crystal
class CustomAuthHandler < Kemal::BasicAuth::Handler
  only ["/dashboard", "/admin"]

  def call(context)
    return call_next(context) unless only_match?(context)
    super
  end
end
```
Now just set `Kemal.config.auth_handler = CustomAuthHandler` and you are good to go.

#### `kemal_authorized_username`

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
