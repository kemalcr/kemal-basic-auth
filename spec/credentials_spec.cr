require "./spec_helper"

describe "HTTPBasicAuth::Credentials" do
  it "#authorize?" do
    entries = {
      "serdar"   => "12345",
      "dogruyol" => "abc",
    }
    crendentials = Kemal::BasicAuth::Credentials.new(entries)

    crendentials.authorize?("serdar", "12345").should eq("serdar")
    crendentials.authorize?("serdar", "xxx").should eq(nil)
    crendentials.authorize?("dogruyol", "abc").should eq("dogruyol")
    crendentials.authorize?("dogruyol", "xxx").should eq(nil)
    crendentials.authorize?("foo", "bar").should eq(nil)
    crendentials.authorize?("foo", "").should eq(nil)
    crendentials.authorize?("", "bar").should eq(nil)
  end
end
