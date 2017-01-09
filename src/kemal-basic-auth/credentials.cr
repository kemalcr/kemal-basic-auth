class HTTPBasicAuth
  class Credentials
    def initialize(@entries : Hash(String, String) = Hash(String, String).new)
    end

    def authorize?(username : String, password : String) : String?
      if @entries[username]? == password
        username
      else
        nil
      end
    end
  end
end
