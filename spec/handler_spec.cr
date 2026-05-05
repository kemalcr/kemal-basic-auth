require "./spec_helper"

describe Kemal::BasicAuth::Handler do
  describe "#call" do
    it "passes through with correct credentials and sets kemal_authorized_username" do
      handler = Kemal::BasicAuth::Handler.new("serdar", "123")
      request = request_from("GET", "/", basic_auth_header("serdar", "123"))

      io, context = create_request_and_return_io_and_context(handler, request)
      response = HTTP::Client::Response.from_io(io, decompress: false)

      response.status_code.should eq(404)
      context.kemal_authorized_username?.should eq("serdar")
    end

    it "returns 401 with no Authorization header" do
      handler = Kemal::BasicAuth::Handler.new("serdar", "123")
      request = request_from("GET", "/")

      io, context = create_request_and_return_io_and_context(handler, request)
      response = HTTP::Client::Response.from_io(io, decompress: false)

      response.status_code.should eq(401)
      response.headers["WWW-Authenticate"].should eq(%(Basic realm="Login Required"))
      context.kemal_authorized_username?.should be_nil
    end

    it "returns 401 with non-Basic scheme" do
      handler = Kemal::BasicAuth::Handler.new("serdar", "123")
      request = request_from("GET", "/", "Bearer abc.def.ghi")

      response_status(handler, request).should eq(401)
    end

    it "returns 401 with malformed prefix (no space after Basic)" do
      handler = Kemal::BasicAuth::Handler.new("serdar", "123")
      request = request_from("GET", "/", "BasicXYZ")

      response_status(handler, request).should eq(401)
    end

    it "returns 401 with invalid Base64 payload" do
      handler = Kemal::BasicAuth::Handler.new("serdar", "123")
      request = request_from("GET", "/", "Basic !!!not-base64!!!")

      response_status(handler, request).should eq(401)
    end

    it "returns 401 when decoded payload contains no colon" do
      handler = Kemal::BasicAuth::Handler.new("serdar", "123")
      payload = Base64.strict_encode("nocolonhere")
      request = request_from("GET", "/", "Basic #{payload}")

      response_status(handler, request).should eq(401)
    end

    it "returns 401 with wrong password" do
      handler = Kemal::BasicAuth::Handler.new("serdar", "123")
      request = request_from("GET", "/", basic_auth_header("serdar", "wrong"))

      response_status(handler, request).should eq(401)
    end

    it "supports passwords containing colons" do
      handler = Kemal::BasicAuth::Handler.new("serdar", "p:a:s:s")
      request = request_from("GET", "/", basic_auth_header("serdar", "p:a:s:s"))

      response_status(handler, request).should eq(404)
    end

    it "tolerates extra whitespace in the header value" do
      payload = Base64.strict_encode("serdar:123")
      handler = Kemal::BasicAuth::Handler.new("serdar", "123")
      request = request_from("GET", "/", "Basic   #{payload}  ")

      response_status(handler, request).should eq(404)
    end

    it "authenticates any of multiple users" do
      handler = Kemal::BasicAuth::Handler.new({"alice" => "a", "bob" => "b"})

      response_status(handler, request_from("GET", "/", basic_auth_header("alice", "a"))).should eq(404)
      response_status(handler, request_from("GET", "/", basic_auth_header("bob", "b"))).should eq(404)
      response_status(handler, request_from("GET", "/", basic_auth_header("alice", "b"))).should eq(401)
      response_status(handler, request_from("GET", "/", basic_auth_header("eve", "x"))).should eq(401)
    end
  end

  describe "realm and message customization" do
    it "uses the configured realm in WWW-Authenticate" do
      handler = Kemal::BasicAuth::Handler.new("u", "p", realm: "My API")
      request = request_from("GET", "/")

      io, _ = create_request_and_return_io_and_context(handler, request)
      response = HTTP::Client::Response.from_io(io, decompress: false)

      response.headers["WWW-Authenticate"].should eq(%(Basic realm="My API"))
    end

    it "uses the configured 401 body" do
      handler = Kemal::BasicAuth::Handler.new("u", "p", message: "Forbidden!")
      request = request_from("GET", "/")

      io, _ = create_request_and_return_io_and_context(handler, request)
      response = HTTP::Client::Response.from_io(io, decompress: false)

      response.body.should eq("Forbidden!")
    end

    it "sanitizes quotes and CRLF from realm to prevent header injection" do
      handler = Kemal::BasicAuth::Handler.new("u", "p", realm: %(evil"\r\nX-Injected: yes))
      request = request_from("GET", "/")

      io, _ = create_request_and_return_io_and_context(handler, request)
      response = HTTP::Client::Response.from_io(io, decompress: false)

      header = response.headers["WWW-Authenticate"]
      header.should_not contain("\r")
      header.should_not contain("\n")
      header.should eq(%(Basic realm="evilX-Injected: yes"))
    end
  end
end
