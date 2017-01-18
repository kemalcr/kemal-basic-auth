class HTTPBasicAuth 
  class Credentials
    alias Entries = Hash(String, String)

    def initialize(@entries : Entries = Entries.new)
    end

    def authorize?(username : String, password : String) : String?
      if @entries[username]? == password
        username
      else
        nil
      end
    end

    def update(username : String, password : String)
      @entries[username] = password
    end

    def update(other : Entries)
      @entries.merge!(other)
    end
  end
end
