require "base64"
require "kemal"
require "crypto/subtle"
require "./basic_auth/*"
require "./ext/*"

module Kemal
  module BasicAuth
  end
end

# Helper to easily add Basic Auth support.
def basic_auth(username, password)
  add_handler Kemal::BasicAuth::Handler.new(username, password)
end

def basic_auth(crendentials : Hash(String, String))
  add_handler Kemal::BasicAuth::Handler.new(crendentials)
end
