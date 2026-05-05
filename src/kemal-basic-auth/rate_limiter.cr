module Kemal::BasicAuth
  # Simple in-memory sliding-window rate limiter for failed authentication
  # attempts. Tracks failures per key (typically the remote address) and
  # treats a key as "limited" once the configured threshold is reached
  # within the window.
  #
  # Thread-safe via an internal `Mutex`. Memory grows with the number of
  # distinct keys; `purge_expired` may be called periodically to drop
  # entries whose attempts have all aged out.
  #
  # ```
  # limiter = Kemal::BasicAuth::RateLimiter.new(max_attempts: 5, window: 1.minute)
  # ```
  class RateLimiter
    DEFAULT_MAX_ATTEMPTS = 5
    DEFAULT_WINDOW       = 1.minute

    getter max_attempts : Int32
    getter window : Time::Span

    def initialize(@max_attempts : Int32 = DEFAULT_MAX_ATTEMPTS,
                   @window : Time::Span = DEFAULT_WINDOW,
                   @clock : -> Time = -> { Time.utc })
      @attempts = {} of String => Array(Time)
      @mutex = Mutex.new
    end

    # Records a failed attempt for the given key and returns the number of
    # attempts within the active window after this one was recorded.
    def record_failure(key : String) : Int32
      @mutex.synchronize do
        list = active_attempts(key)
        list << @clock.call
        list.size
      end
    end

    # Returns true if the key has reached or exceeded `max_attempts` within
    # the active window.
    def limited?(key : String) : Bool
      @mutex.synchronize do
        list = active_attempts(key)
        @attempts.delete(key) if list.empty?
        list.size >= @max_attempts
      end
    end

    # Clears any recorded failures for the key (e.g. after a successful login).
    def reset(key : String) : Nil
      @mutex.synchronize { @attempts.delete(key) }
    end

    # Drops entries whose attempts have all aged out of the window.
    def purge_expired : Nil
      @mutex.synchronize do
        @attempts.each_key do |key|
          active_attempts(key)
          @attempts.delete(key) if @attempts[key]?.try(&.empty?)
        end
      end
    end

    # NOTE: caller must hold @mutex.
    private def active_attempts(key : String) : Array(Time)
      list = @attempts[key] ||= [] of Time
      cutoff = @clock.call - @window
      list.reject! { |time| time < cutoff }
      list
    end
  end
end
