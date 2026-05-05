require "kemal"
require "./kemal-basic-auth/**"

module Kemal
  module BasicAuth
  end
end

# Helper to easily add HTTP Basic Auth support.
def basic_auth(username : String, password : String,
               realm : String = Kemal::BasicAuth::Handler::DEFAULT_REALM,
               message : String = Kemal::BasicAuth::Handler::AUTH_MESSAGE)
  add_handler Kemal.config.auth_handler.new(username, password, realm, message)
end

def basic_auth(credentials : Hash(String, String),
               realm : String = Kemal::BasicAuth::Handler::DEFAULT_REALM,
               message : String = Kemal::BasicAuth::Handler::AUTH_MESSAGE)
  add_handler Kemal.config.auth_handler.new(credentials, realm, message)
end

def basic_auth(verifier : Kemal::BasicAuth::Verifier,
               realm : String = Kemal::BasicAuth::Handler::DEFAULT_REALM,
               message : String = Kemal::BasicAuth::Handler::AUTH_MESSAGE)
  add_handler Kemal.config.auth_handler.new(verifier, realm, message)
end
