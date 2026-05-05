require "./spec_helper"

describe "HTTPBasicAuth::Credentials" do
  it "#authorize?" do
    entries = {
      "serdar"   => "12345",
      "dogruyol" => "abc",
    }
    credentials = Kemal::BasicAuth::Credentials.new(entries)

    credentials.authorize?("serdar", "12345").should eq("serdar")
    credentials.authorize?("serdar", "xxx").should eq(nil)
    credentials.authorize?("dogruyol", "abc").should eq("dogruyol")
    credentials.authorize?("dogruyol", "xxx").should eq(nil)
    credentials.authorize?("foo", "bar").should eq(nil)
    credentials.authorize?("foo", "").should eq(nil)
    credentials.authorize?("", "bar").should eq(nil)
  end
end
