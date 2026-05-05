require "spec"
require "../src/kemal-basic-auth"

# Legacy custom handler pattern (manual `call` override).
# Kept to verify backward compatibility with the pre-1.1 README example.
class LegacyOnlyHandler < Kemal::BasicAuth::Handler
  only ["/admin"]

  def call(context)
    return call_next(context) unless only_match?(context)
    super
  end
end

# New automatic pattern: base `call` handles `only`/`exclude` filtering.
class AutoOnlyHandler < Kemal::BasicAuth::Handler
  only ["/admin", "/dashboard"]
end

class AutoExcludeHandler < Kemal::BasicAuth::Handler
  exclude ["/health", "/metrics"]
end

class AutoOnlyExcludeHandler < Kemal::BasicAuth::Handler
  only ["/admin"]
  exclude ["/admin/public"]
end

def create_request_and_return_io_and_context(handler, request)
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  handler.call(context)
  response.close
  io.rewind
  {io, context}
end

# Build a Basic auth `Authorization` header value from username/password.
def basic_auth_header(username : String, password : String) : String
  "Basic " + Base64.strict_encode("#{username}:#{password}")
end

# Build a request with an attached fake remote address so rate-limit logic
# can key off the source.
def request_from(method : String, path : String,
                 auth_value : String? = nil,
                 remote : String? = "127.0.0.1:54321") : HTTP::Request
  headers = HTTP::Headers.new
  headers["Authorization"] = auth_value if auth_value
  request = HTTP::Request.new(method, path, headers: headers)
  if remote
    host, _, port = remote.rpartition(":")
    request.remote_address = Socket::IPAddress.new(host, port.to_i)
  end
  request
end

def response_status(handler, request) : Int32
  io, _ = create_request_and_return_io_and_context(handler, request)
  HTTP::Client::Response.from_io(io, decompress: false).status_code
end
