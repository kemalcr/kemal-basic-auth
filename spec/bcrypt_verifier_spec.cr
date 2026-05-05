require "./spec_helper"
require "crypto/bcrypt/password"

describe Kemal::BasicAuth::BcryptVerifier do
  # cost: 4 keeps tests fast; production should use the default cost.
  hash_for = ->(plain : String) { Crypto::Bcrypt::Password.create(plain, cost: 4).to_s }

  it "authorizes a user with a matching bcrypt hash" do
    verifier = Kemal::BasicAuth::BcryptVerifier.new({
      "admin" => hash_for.call("xyz"),
      "guest" => hash_for.call("123"),
    })

    verifier.authorize?("admin", "xyz").should eq("admin")
    verifier.authorize?("guest", "123").should eq("guest")
  end

  it "rejects a wrong password" do
    verifier = Kemal::BasicAuth::BcryptVerifier.new({"admin" => hash_for.call("xyz")})

    verifier.authorize?("admin", "wrong").should be_nil
  end

  it "rejects an unknown username" do
    verifier = Kemal::BasicAuth::BcryptVerifier.new({"admin" => hash_for.call("xyz")})

    verifier.authorize?("ghost", "xyz").should be_nil
  end

  it "rejects a malformed hash without raising" do
    verifier = Kemal::BasicAuth::BcryptVerifier.new({"admin" => "not-a-bcrypt-hash"})

    verifier.authorize?("admin", "xyz").should be_nil
  end

  it "integrates with the Handler" do
    verifier = Kemal::BasicAuth::BcryptVerifier.new({"admin" => hash_for.call("xyz")})
    handler = Kemal::BasicAuth::Handler.new(verifier)

    response_status(handler, request_from("GET", "/", basic_auth_header("admin", "xyz"))).should eq(404)
    response_status(handler, request_from("GET", "/", basic_auth_header("admin", "nope"))).should eq(401)
    response_status(handler, request_from("GET", "/", basic_auth_header("ghost", "xyz"))).should eq(401)
  end
end
