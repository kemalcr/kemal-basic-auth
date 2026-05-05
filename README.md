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

#### Hashed passwords with bcrypt

For production credentials, store bcrypt hashes rather than plaintext:

```crystal
require "crypto/bcrypt/password"

hash = Crypto::Bcrypt::Password.create("xyz").to_s
verifier = Kemal::BasicAuth::BcryptVerifier.new({"admin" => hash})
basic_auth verifier
```

#### Dynamic credentials (database, environment, ...)

The block form lets you decide whether a username/password is valid at request
time, e.g. by looking up a row in your database:

```crystal
basic_auth do |user, pass|
  User.authenticate(user, pass)
end

# realm/message/rate_limiter can still be configured:
basic_auth(realm: "My API") do |user, pass|
  User.authenticate(user, pass)
end
```

#### Throttling failed attempts

A simple in-memory rate limiter can be attached to slow down brute-force
attempts. The limiter keys off the request's remote address; once a threshold
is reached the handler responds with `429 Too Many Requests` and a
`Retry-After` header until the window elapses.

```crystal
limiter = Kemal::BasicAuth::RateLimiter.new(max_attempts: 5, window: 1.minute)
basic_auth "username", "password", rate_limiter: limiter
```

A successful authentication clears the counter for that remote.

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

`exclude` works the same way and can be combined with `only` (`exclude` takes
precedence):

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
