require "crypto/bcrypt/password"
require "crypto/subtle"
require "./verifier"

module Kemal::BasicAuth
  # Verifier backed by bcrypt-hashed passwords.
  #
  # Entries map a username to an existing bcrypt hash string (e.g. produced via
  # `Crypto::Bcrypt::Password.create("plain").to_s`). Verification always
  # performs a bcrypt computation (real or dummy) so that response time does
  # not reveal whether the username exists.
  #
  # ```
  # hash = Crypto::Bcrypt::Password.create("xyz").to_s
  # verifier = Kemal::BasicAuth::BcryptVerifier.new({"admin" => hash})
  # ```
  class BcryptVerifier < Verifier
    # A pre-computed hash of an arbitrary value used for the dummy verify path
    # to keep timing comparable with the real verify path. Created lazily on
    # first access (bcrypt key derivation is intentionally slow).
    @@dummy_hash : String?

    def self.dummy_hash : String
      @@dummy_hash ||= Crypto::Bcrypt::Password.create("kemal-basic-auth-dummy", cost: Crypto::Bcrypt::DEFAULT_COST).to_s
    end

    def initialize(@entries : Hash(String, String))
    end

    def authorize?(username : String, password : String) : String?
      stored_hash = lookup(username)
      if stored_hash
        bcrypt = Crypto::Bcrypt::Password.new(stored_hash)
        bcrypt.verify(password) ? username : nil
      else
        Crypto::Bcrypt::Password.new(self.class.dummy_hash).verify(password)
        nil
      end
    rescue Crypto::Bcrypt::Error
      nil
    end

    # Iterate all entries with constant-time compare to avoid leaking which
    # usernames exist via timing.
    private def lookup(username : String) : String?
      result : String? = nil
      @entries.each do |user, hash|
        if Crypto::Subtle.constant_time_compare(user, username)
          result = hash
        end
      end
      result
    end
  end
end
