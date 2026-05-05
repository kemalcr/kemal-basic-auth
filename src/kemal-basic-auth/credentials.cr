require "crypto/subtle"
require "digest/sha256"
require "./verifier"

module Kemal::BasicAuth
  # Plaintext credentials verifier backed by a `Hash(String, String)`.
  #
  # Comparison is performed in length-equalized form (SHA-256 digests) so the
  # response time does not depend on whether the username exists or how the
  # given password compares to the stored one. SHA-256 is used purely for
  # timing equalization here, not for password storage; if you need hashed
  # storage use `BcryptVerifier`.
  class Credentials < Verifier
    def initialize(@entries : Hash(String, String) = Hash(String, String).new)
    end

    def authorize?(username : String, password : String) : String?
      given_hash = Digest::SHA256.hexdigest(password)
      stored_password = ""
      matched_user = false

      @entries.each do |user, entry_password|
        if Crypto::Subtle.constant_time_compare(user, username)
          stored_password = entry_password
          matched_user = true
        end
      end

      stored_hash = Digest::SHA256.hexdigest(stored_password)
      password_ok = Crypto::Subtle.constant_time_compare(stored_hash, given_hash)

      (matched_user && password_ok) ? username : nil
    end
  end
end
