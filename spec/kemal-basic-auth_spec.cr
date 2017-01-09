require "./spec_helper"

describe "HTTPBasicAuth" do
  it "goes to next handler with correct credentials" do
    auth_handler = HTTPBasicAuth.new("serdar", "123")
    request = HTTP::Request.new(
      "GET",
      "/",
      headers: HTTP::Headers{"Authorization" => "Basic c2VyZGFyOjEyMw=="},
    )

    io, context = create_request_and_return_io_and_context(auth_handler, request)
    client_response = HTTP::Client::Response.from_io(io, decompress: false)
    client_response.status_code.should eq 404
    context.kemal_authorized_username?.should eq("serdar")
  end

  it "returns 401 with incorrect credentials" do
    auth_handler = HTTPBasicAuth.new("serdar", "123")
    request = HTTP::Request.new(
      "GET",
      "/",
      headers: HTTP::Headers{"Authorization" => "NotBasic"},
    )
    io, context = create_request_and_return_io_and_context(auth_handler, request)
    client_response = HTTP::Client::Response.from_io(io, decompress: false)
    client_response.status_code.should eq 401
    context.kemal_authorized_username?.should eq(nil)
  end

  it "adds HTTPBasicAuthHandler" do
    basic_auth "serdar", "123"
    Kemal.config.handlers.size.should eq 6
  end
end
