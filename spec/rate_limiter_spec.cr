require "./spec_helper"

# Test helper: mutable clock that lets specs control "now" without sleeping.
class FakeClock
  property now : Time

  def initialize(@now : Time = Time.utc(2024, 1, 1))
  end

  def advance(span : Time::Span)
    @now += span
  end

  def to_proc
    -> { @now }
  end
end

describe Kemal::BasicAuth::RateLimiter do
  it "starts unlimited and records failures up to the threshold" do
    limiter = Kemal::BasicAuth::RateLimiter.new(max_attempts: 3, window: 60.seconds)

    limiter.limited?("ip-a").should be_false
    limiter.record_failure("ip-a").should eq(1)
    limiter.record_failure("ip-a").should eq(2)
    limiter.limited?("ip-a").should be_false
    limiter.record_failure("ip-a").should eq(3)
    limiter.limited?("ip-a").should be_true
  end

  it "isolates counters per key" do
    limiter = Kemal::BasicAuth::RateLimiter.new(max_attempts: 2, window: 60.seconds)
    limiter.record_failure("a")
    limiter.record_failure("a")

    limiter.limited?("a").should be_true
    limiter.limited?("b").should be_false
  end

  it "drops attempts that have aged out of the window" do
    clock = FakeClock.new
    limiter = Kemal::BasicAuth::RateLimiter.new(max_attempts: 2, window: 60.seconds, clock: clock.to_proc)

    limiter.record_failure("ip")
    limiter.record_failure("ip")
    limiter.limited?("ip").should be_true

    clock.advance(61.seconds)
    limiter.limited?("ip").should be_false
  end

  it "reset clears the counter" do
    limiter = Kemal::BasicAuth::RateLimiter.new(max_attempts: 2, window: 60.seconds)
    limiter.record_failure("ip")
    limiter.record_failure("ip")
    limiter.limited?("ip").should be_true

    limiter.reset("ip")
    limiter.limited?("ip").should be_false
  end

  describe "Handler integration" do
    it "responds with 429 once the threshold is exceeded" do
      limiter = Kemal::BasicAuth::RateLimiter.new(max_attempts: 2, window: 60.seconds)
      handler = Kemal::BasicAuth::Handler.new("u", "p", rate_limiter: limiter)

      bad = -> { request_from("GET", "/", basic_auth_header("u", "wrong")) }

      response_status(handler, bad.call).should eq(401)
      response_status(handler, bad.call).should eq(401)

      io, _ = create_request_and_return_io_and_context(handler, bad.call)
      response = HTTP::Client::Response.from_io(io, decompress: false)
      response.status_code.should eq(429)
      response.headers["Retry-After"]?.should eq("60")
    end

    it "resets the counter on successful authentication" do
      limiter = Kemal::BasicAuth::RateLimiter.new(max_attempts: 3, window: 60.seconds)
      handler = Kemal::BasicAuth::Handler.new("u", "p", rate_limiter: limiter)

      response_status(handler, request_from("GET", "/", basic_auth_header("u", "wrong"))).should eq(401)
      response_status(handler, request_from("GET", "/", basic_auth_header("u", "wrong"))).should eq(401)
      response_status(handler, request_from("GET", "/", basic_auth_header("u", "p"))).should eq(404)
      # Counter was reset; another wrong attempt should still get 401, not 429.
      response_status(handler, request_from("GET", "/", basic_auth_header("u", "wrong"))).should eq(401)
    end

    it "skips rate limiting when the request has no remote address" do
      limiter = Kemal::BasicAuth::RateLimiter.new(max_attempts: 1, window: 60.seconds)
      handler = Kemal::BasicAuth::Handler.new("u", "p", rate_limiter: limiter)

      bad = -> { request_from("GET", "/", basic_auth_header("u", "wrong"), remote: nil) }

      response_status(handler, bad.call).should eq(401)
      response_status(handler, bad.call).should eq(401)
      response_status(handler, bad.call).should eq(401)
    end
  end
end
