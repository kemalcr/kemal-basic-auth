require "./spec_helper"

# These specs exercise the auto-`only`/auto-`exclude` behavior added in 1.1
# along with the legacy manual override pattern still documented in the README.
describe "only/exclude path filtering" do
  describe "AutoOnlyHandler (no `call` override)" do
    it "authenticates configured paths" do
      handler = AutoOnlyHandler.new("u", "p")
      response_status(handler, request_from("GET", "/admin")).should eq(401)
      response_status(handler, request_from("GET", "/dashboard")).should eq(401)
    end

    it "passes through unconfigured paths" do
      handler = AutoOnlyHandler.new("u", "p")
      response_status(handler, request_from("GET", "/public")).should eq(404)
      response_status(handler, request_from("GET", "/")).should eq(404)
    end

    it "lets correct credentials through to the next handler on configured paths" do
      handler = AutoOnlyHandler.new("u", "p")
      response_status(handler, request_from("GET", "/admin", basic_auth_header("u", "p"))).should eq(404)
    end
  end

  describe "AutoExcludeHandler" do
    it "passes through excluded paths without challenging" do
      handler = AutoExcludeHandler.new("u", "p")
      response_status(handler, request_from("GET", "/health")).should eq(404)
      response_status(handler, request_from("GET", "/metrics")).should eq(404)
    end

    it "authenticates non-excluded paths" do
      handler = AutoExcludeHandler.new("u", "p")
      response_status(handler, request_from("GET", "/api")).should eq(401)
    end
  end

  describe "AutoOnlyExcludeHandler" do
    it "exclude takes precedence over only" do
      handler = AutoOnlyExcludeHandler.new("u", "p")
      response_status(handler, request_from("GET", "/admin/public")).should eq(404)
      response_status(handler, request_from("GET", "/admin")).should eq(401)
      response_status(handler, request_from("GET", "/anything-else")).should eq(404)
    end
  end

  describe "LegacyOnlyHandler (manual `call` override)" do
    it "still works with the pre-1.1 README pattern" do
      handler = LegacyOnlyHandler.new("u", "p")
      response_status(handler, request_from("GET", "/admin")).should eq(401)
      response_status(handler, request_from("GET", "/admin", basic_auth_header("u", "p"))).should eq(404)
      response_status(handler, request_from("GET", "/public")).should eq(404)
    end
  end

  describe "default Handler (no only/exclude)" do
    it "authenticates every path" do
      handler = Kemal::BasicAuth::Handler.new("u", "p")
      response_status(handler, request_from("GET", "/anything")).should eq(401)
      response_status(handler, request_from("GET", "/", basic_auth_header("u", "p"))).should eq(404)
    end
  end
end
