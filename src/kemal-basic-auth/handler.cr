require "base64"

module Kemal::BasicAuth
  # This middleware adds HTTP Basic Auth support to your application.
  # Returns 401 "Unauthorized" with wrong credentials.
  #
  # ```
  # basic_auth "username", "password"
  # # basic_auth({"username1" => "password1", "username2" => "password2"})
  # ```
  #
  # `HTTP::Server::Context#kemal_authorized_username?` is set when the user is
  # authorized.
  class Handler < Kemal::Handler
    BASIC                  = "Basic"
    BASIC_PREFIX           = "Basic "
    AUTH                   = "Authorization"
    AUTH_MESSAGE           = "Could not verify your access level for that URL.\nYou have to login with proper credentials"
    DEFAULT_REALM          = "Login Required"
    HEADER_LOGIN_REQUIRED  = %(Basic realm="#{DEFAULT_REALM}")
    RATE_LIMIT_MESSAGE     = "Too many failed authentication attempts. Please try again later."
    RATE_LIMIT_RETRY_AFTER = "60"

    # Tracks which subclasses configured `only`/`exclude` so the base `call`
    # can decide whether to enforce path filtering automatically.
    @@bauth_only_classes = Set(String).new
    @@bauth_exclude_classes = Set(String).new

    getter realm : String
    getter message : String
    getter rate_limiter : RateLimiter?

    def initialize(@verifier : Verifier,
                   @realm : String = DEFAULT_REALM,
                   @message : String = AUTH_MESSAGE,
                   @rate_limiter : RateLimiter? = nil)
    end

    # backward compatibility
    def initialize(username : String, password : String,
                   realm : String = DEFAULT_REALM,
                   message : String = AUTH_MESSAGE,
                   rate_limiter : RateLimiter? = nil)
      initialize(Credentials.new({username => password}), realm, message, rate_limiter)
    end

    def initialize(hash : Hash(String, String),
                   realm : String = DEFAULT_REALM,
                   message : String = AUTH_MESSAGE,
                   rate_limiter : RateLimiter? = nil)
      initialize(Credentials.new(hash), realm, message, rate_limiter)
    end

    macro only(paths, method = "GET")
      class_name = {{ @type.name }}
      class_name_method = "#{class_name}/#{{{ method }}}"
      ({{ paths }}).each do |path|
        @@only_routes_tree.add class_name_method + path, '/' + {{ method }} + path
      end
      @@bauth_only_classes << {{ @type.name.stringify }}
    end

    macro exclude(paths, method = "GET")
      class_name = {{ @type.name }}
      class_name_method = "#{class_name}/#{{{ method }}}"
      ({{ paths }}).each do |path|
        @@exclude_routes_tree.add class_name_method + path, '/' + {{ method }} + path
      end
      @@bauth_exclude_classes << {{ @type.name.stringify }}
    end

    def call(context)
      klass = self.class.name
      if @@bauth_exclude_classes.includes?(klass) && exclude_match?(context)
        return call_next(context)
      end
      if @@bauth_only_classes.includes?(klass) && !only_match?(context)
        return call_next(context)
      end
      authenticate(context)
    end

    protected def authenticate(context)
      remote = remote_key(context)

      if remote && (limiter = @rate_limiter) && limiter.limited?(remote)
        return reject_rate_limited(context)
      end

      if (value = context.request.headers[AUTH]?) && value.starts_with?(BASIC_PREFIX)
        if username = authorize?(value)
          context.kemal_authorized_username = username
          @rate_limiter.try(&.reset(remote)) if remote
          return call_next(context)
        end
      end

      @rate_limiter.try(&.record_failure(remote)) if remote
      reject_unauthorized(context)
    end

    def authorize?(value) : String?
      encoded = value[BASIC_PREFIX.size..-1].strip
      decoded = Base64.decode_string(encoded)
      username, separator, password = decoded.partition(":")
      return nil if separator.empty?
      @verifier.authorize?(username, password)
    rescue Base64::Error
      nil
    end

    private def remote_key(context) : String?
      addr = context.request.remote_address
      addr ? addr.to_s : nil
    end

    private def reject_rate_limited(context)
      context.response.status_code = 429
      context.response.headers["Retry-After"] = RATE_LIMIT_RETRY_AFTER
      context.response.print RATE_LIMIT_MESSAGE
    end

    private def reject_unauthorized(context)
      context.response.status_code = 401
      context.response.headers["WWW-Authenticate"] = login_required_header
      context.response.print @message
    end

    private def login_required_header : String
      safe_realm = @realm.gsub(/["\r\n]/, "")
      %(Basic realm="#{safe_realm}")
    end
  end
end
