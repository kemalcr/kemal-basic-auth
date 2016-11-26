require "base64"
require "kemal"

# This middleware adds HTTP Basic Auth support to your application.
# Returns 401 "Unauthorized" with wrong credentials.
#
# basic_auth "username", "password"
#
class HTTPBasicAuth < HTTP::Handler
  BASIC                 = "Basic"
  AUTH                  = "Authorization"
  AUTH_MESSAGE          = "Could not verify your access level for that URL.\nYou have to login with proper credentials"
  HEADER_LOGIN_REQUIRED = "Basic realm=\"Login Required\""

  def initialize(@username : String?, @password : String?)
  end

  def call(context)
    if context.request.headers[AUTH]?
      if value = context.request.headers[AUTH]
        if value.size > 0 && value.starts_with?(BASIC)
          return call_next(context) if authorized?(value)
        end
      end
    end
    headers = HTTP::Headers.new
    context.response.status_code = 401
    context.response.headers["WWW-Authenticate"] = HEADER_LOGIN_REQUIRED
    context.response.print AUTH_MESSAGE
  end

  def authorized?(value)
    username, password = Base64.decode_string(value[BASIC.size + 1..-1]).split(":")
    @username == username && @password == password
  end
end

# Helper to easily add HTTP Basic Auth support.
def basic_auth(username, password)
  add_handler HTTPBasicAuth.new(username, password)
end
