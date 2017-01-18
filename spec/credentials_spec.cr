require "./spec_helper"

describe "HTTPBasicAuth::Credentials" do
  it "#authorize?" do
    entries = {
      "serdar"   => "123",
      "dogruyol" => "abc",
    }
    credentials = HTTPBasicAuth::Credentials.new(entries)

    credentials.authorize?("serdar"  , "123").should eq("serdar")
    credentials.authorize?("serdar"  , "xxx").should eq(nil)
    credentials.authorize?("dogruyol", "abc").should eq("dogruyol")
    credentials.authorize?("dogruyol", "xxx").should eq(nil)
    credentials.authorize?("foo"     , "bar").should eq(nil)
  end

  describe "#update" do
    credentials = HTTPBasicAuth::Credentials.new

    it "(String, String) adds a new entry" do
      credentials.authorize?("serdar", "123").should eq(nil)
      credentials.update("serdar", "123")
      credentials.authorize?("serdar", "123").should eq("serdar")
      credentials.authorize?("serdar", "xxx").should eq(nil)
    end

    it "(Hash) adds new entries" do
      credentials.update({"a" => "1", "b" => "2"})
      credentials.authorize?("a", "1").should eq("a")
      credentials.authorize?("a", "x").should eq(nil)
      credentials.authorize?("b", "2").should eq("b")
      credentials.authorize?("c", "3").should eq(nil)
    end

    it "preserves accumulated entries" do
      credentials.authorize?("serdar", "123").should eq("serdar")
    end
  end
end
