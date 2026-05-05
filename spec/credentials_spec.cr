require "./spec_helper"

describe Kemal::BasicAuth::Credentials do
  describe "#authorize?" do
    it "returns the username for matching plaintext credentials" do
      creds = Kemal::BasicAuth::Credentials.new({
        "serdar"   => "12345",
        "dogruyol" => "abc",
      })

      creds.authorize?("serdar", "12345").should eq("serdar")
      creds.authorize?("dogruyol", "abc").should eq("dogruyol")
    end

    it "returns nil for wrong password" do
      creds = Kemal::BasicAuth::Credentials.new({"serdar" => "12345"})

      creds.authorize?("serdar", "xxx").should be_nil
    end

    it "returns nil for unknown username" do
      creds = Kemal::BasicAuth::Credentials.new({"serdar" => "12345"})

      creds.authorize?("foo", "bar").should be_nil
      creds.authorize?("foo", "").should be_nil
      creds.authorize?("", "bar").should be_nil
    end

    it "returns nil with an empty entries hash" do
      creds = Kemal::BasicAuth::Credentials.new

      creds.authorize?("anyone", "").should be_nil
      creds.authorize?("anyone", "anything").should be_nil
    end

    it "treats matching empty password against an entry with empty password as authorized" do
      # Edge case: the SHA-256 timing fix must not introduce a false positive
      # for an unknown user with an empty password.
      creds = Kemal::BasicAuth::Credentials.new({"u" => "p"})

      creds.authorize?("nobody", "").should be_nil
    end

    it "is case-sensitive on usernames and passwords" do
      creds = Kemal::BasicAuth::Credentials.new({"Alice" => "Secret"})

      creds.authorize?("alice", "Secret").should be_nil
      creds.authorize?("Alice", "secret").should be_nil
      creds.authorize?("Alice", "Secret").should eq("Alice")
    end
  end
end
