require "./spec_helper"

describe "HTTPBasicAuth::Credentials" do
  it "#authorize?" do
    entries = {
      "serdar"   => "123",
      "dogruyol" => "abc",
    }
    crendentials = HTTPBasicAuth::Credentials.new(entries)

    crendentials.authorize?("serdar"  , "123").should eq("serdar")
    crendentials.authorize?("serdar"  , "xxx").should eq(nil)
    crendentials.authorize?("dogruyol", "abc").should eq("dogruyol")
    crendentials.authorize?("dogruyol", "xxx").should eq(nil)
    crendentials.authorize?("foo"     , "bar").should eq(nil)
  end
end
