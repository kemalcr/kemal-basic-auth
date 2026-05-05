require "./spec_helper"

describe Kemal::BasicAuth::ProcVerifier do
  it "delegates to the supplied callback and returns the username on success" do
    verifier = Kemal::BasicAuth::ProcVerifier.new do |user, pass|
      user == "alice" && pass == "wonderland"
    end

    verifier.authorize?("alice", "wonderland").should eq("alice")
    verifier.authorize?("alice", "nope").should be_nil
    verifier.authorize?("eve", "wonderland").should be_nil
  end

  it "is invoked exactly once per authorize? call" do
    calls = 0
    verifier = Kemal::BasicAuth::ProcVerifier.new do |_, _|
      calls += 1
      true
    end

    verifier.authorize?("a", "b")
    verifier.authorize?("c", "d")

    calls.should eq(2)
  end

  it "integrates with the Handler" do
    verifier = Kemal::BasicAuth::ProcVerifier.new do |user, pass|
      user == "admin" && pass == "secret"
    end
    handler = Kemal::BasicAuth::Handler.new(verifier)

    response_status(handler, request_from("GET", "/", basic_auth_header("admin", "secret"))).should eq(404)
    response_status(handler, request_from("GET", "/", basic_auth_header("admin", "wrong"))).should eq(401)
  end
end
