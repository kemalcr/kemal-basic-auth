module Kemal
  class Config
    property auth_handler : Kemal::BasicAuth::Handler.class = Kemal::BasicAuth::Handler
  end
end