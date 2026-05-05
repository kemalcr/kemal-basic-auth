require "kemal"
require "./kemal-basic-auth/**"

module Kemal
  module BasicAuth
  end
end

# Helper to easily add HTTP Basic Auth support.
def basic_auth(username : String, password : String,
               realm : String = Kemal::BasicAuth::Handler::DEFAULT_REALM,
               message : String = Kemal::BasicAuth::Handler::AUTH_MESSAGE,
               rate_limiter : Kemal::BasicAuth::RateLimiter? = nil)
  add_handler Kemal.config.auth_handler.new(username, password, realm, message, rate_limiter)
end

def basic_auth(credentials : Hash(String, String),
               realm : String = Kemal::BasicAuth::Handler::DEFAULT_REALM,
               message : String = Kemal::BasicAuth::Handler::AUTH_MESSAGE,
               rate_limiter : Kemal::BasicAuth::RateLimiter? = nil)
  add_handler Kemal.config.auth_handler.new(credentials, realm, message, rate_limiter)
end

def basic_auth(verifier : Kemal::BasicAuth::Verifier,
               realm : String = Kemal::BasicAuth::Handler::DEFAULT_REALM,
               message : String = Kemal::BasicAuth::Handler::AUTH_MESSAGE,
               rate_limiter : Kemal::BasicAuth::RateLimiter? = nil)
  add_handler Kemal.config.auth_handler.new(verifier, realm, message, rate_limiter)
end

# Block-based variant: credentials are validated by a user-supplied callback.
#
# ```
# basic_auth do |user, pass|
#   User.authenticate(user, pass)
# end
# ```
def basic_auth(realm : String = Kemal::BasicAuth::Handler::DEFAULT_REALM,
               message : String = Kemal::BasicAuth::Handler::AUTH_MESSAGE,
               rate_limiter : Kemal::BasicAuth::RateLimiter? = nil,
               &block : String, String -> Bool)
  verifier = Kemal::BasicAuth::ProcVerifier.new(&block)
  add_handler Kemal.config.auth_handler.new(verifier, realm, message, rate_limiter)
end
