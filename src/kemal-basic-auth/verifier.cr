module Kemal::BasicAuth
  # Strategy interface for authenticating a username/password pair.
  #
  # Built-in implementations:
  # - `Credentials` (plaintext, in-memory)
  #
  # Custom verifiers (database-backed, bcrypt, proc-based, etc.) can subclass
  # this and pass the instance to `Handler.new`.
  abstract class Verifier
    # Returns the authorized username on success, or `nil` otherwise.
    abstract def authorize?(username : String, password : String) : String?
  end
end
