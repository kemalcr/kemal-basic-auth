require "./verifier"

module Kemal::BasicAuth
  # Dynamic verifier that delegates to a user-provided callback. Useful when
  # credentials come from a database, environment variables, or any other
  # external source.
  #
  # The callback receives the submitted username and password and must return
  # `true` if the credentials are valid.
  #
  # ```
  # verifier = Kemal::BasicAuth::ProcVerifier.new do |user, pass|
  #   User.authenticate(user, pass)
  # end
  # ```
  #
  # Note: timing characteristics of the callback are the implementer's
  # responsibility. For password storage, prefer hashed comparison
  # (e.g. `Crypto::Bcrypt::Password`).
  class ProcVerifier < Verifier
    def initialize(&block : String, String -> Bool)
      @callback = block
    end

    def authorize?(username : String, password : String) : String?
      @callback.call(username, password) ? username : nil
    end
  end
end
