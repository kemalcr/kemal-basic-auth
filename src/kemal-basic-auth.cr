require "base64"
require "kemal"
require "./kemal-basic-auth/**"

module Kemal
  module BasicAuth
  end
end

# Helper to easily add HTTP Basic Auth support.
def basic_auth(username : String, password : String)
  add_handler Kemal::BasicAuth::Handler.new(username, password)
end

def basic_auth(crendentials : Hash(String, String))
  add_handler Kemal::BasicAuth::Handler.new(crendentials)
end
