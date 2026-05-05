# kemal-basic-auth

Add basic auth to your [Kemal](http://github.com/kemalcr/kemal) application.

> Basic Auth sends credentials Base64-encoded (not encrypted). Always serve your
> application over HTTPS in production to avoid leaking credentials.

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
# basic_auth({"username1" => "password1", "username2" => "password2"})
```

#### Customizing the realm and 401 body

```crystal
basic_auth "username", "password", realm: "My API"
basic_auth({"admin" => "xyz"}, realm: "Admin Area", message: "Stop!")
```

#### Authentication for specific routes

`Kemal::BasicAuth::Handler` inherits from `Kemal::Handler`. With the built-in
`only`/`exclude` macros the base handler automatically restricts authentication
to those routes; you no longer have to override `call`.

```crystal
class CustomAuthHandler < Kemal::BasicAuth::Handler
  only ["/dashboard", "/admin"]
end

Kemal.config.auth_handler = CustomAuthHandler
```

`exclude` works the same way and can be combined with `only`:

```crystal
class CustomAuthHandler < Kemal::BasicAuth::Handler
  exclude ["/health", "/metrics"]
end
```

The legacy manual override pattern from earlier versions still works:

```crystal
class CustomAuthHandler < Kemal::BasicAuth::Handler
  only ["/dashboard", "/admin"]

  def call(context)
    return call_next(context) unless only_match?(context)
    super
  end
end
```

#### `kemal_authorized_username`

`HTTP::Server::Context#kemal_authorized_username?` is set when the user is authorized.

```crystal
basic_auth({"guest" => "123", "admin" => "xyz"})

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
