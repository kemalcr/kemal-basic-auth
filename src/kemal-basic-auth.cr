require "base64"
require "kemal"
require "./kemal-basic-auth/*"

# This middleware adds HTTP Basic Auth support to your application.
# Returns 401 "Unauthorized" with wrong credentials.
#
# ```crystal
# basic_auth "username", "password"
# # basic_auth {"username1" => "password2", "username2" => "password2"}
# ```
#
# `HTTP::Server::Context#authorized_username` is set when the user is
# authorized.
#
class HTTPBasicAuth
  include HTTP::Handler
  BASIC                 = "Basic"
  AUTH                  = "Authorization"
  AUTH_MESSAGE          = "Could not verify your access level for that URL.\nYou have to login with proper credentials"
  HEADER_LOGIN_REQUIRED = "Basic realm=\"Login Required\""

  # a lazy singleton instance which is automatically added to handler in first access
  @@runtime : self?
  def self.runtime
    @@runtime ||= new.tap{|handler| add_handler handler}
    @@runtime.not_nil!
  end

  getter credentials
  delegate update, to: credentials

  def initialize(@credentials : Credentials = Credentials.new)
  end

  # backward compatibility
  def initialize(username : String, password : String)
    initialize({ username => password })
  end

  def initialize(hash : Hash(String, String))
    initialize(Credentials.new(hash))
  end
  
  def call(context)
    if context.request.headers[AUTH]?
      if value = context.request.headers[AUTH]
        if value.size > 0 && value.starts_with?(BASIC)
          if username = authorize?(value)
            context.kemal_authorized_username = username
            return call_next(context)
          end
        end
      end
    end
    headers = HTTP::Headers.new
    context.response.status_code = 401
    context.response.headers["WWW-Authenticate"] = HEADER_LOGIN_REQUIRED
    context.response.print AUTH_MESSAGE
  end

  def authorize?(value) : String?
    username, password = Base64.decode_string(value[BASIC.size + 1..-1]).split(":")
    authorize?(username, password)
  end

  def authorize?(username : String, password : String) : String?
    @credentials.authorize?(username, password)
  end
end

# Helper to easily add HTTP Basic Auth support.
def basic_auth(username, password)
  HTTPBasicAuth.runtime.update(username, password)
end

def basic_auth(crendentials : Hash(String, String))
  HTTPBasicAuth.runtime.update(crendentials)
end
