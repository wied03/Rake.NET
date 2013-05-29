require 'socket'
require 'config'

module BradyW
  # TODO: Merge this in with Base_Config
  # Retrieves database related settings from our YAML configuration files
  class Database

    def initialize
      @config = Config.activeConfiguration
    end

    private

    def prefix
      @config.project_prefix
    end

    public

    CREDENTIALS = [:system, :objectcreation, :general]

    # The hostname where the database lives (db: => hostname:)
    def host
      @config.db_hostname
    end

    # The name of the database/catalog  (db: => name:)
    def name
      @config.db_name.gsub(/@thismachinehostname@/, Socket.gethostname).
          gsub(/@prefix@/, prefix)
    end

    # General user's username
    def user
      @config.db_general_user.gsub(/@thismachinehostname@/, Socket.gethostname).
          gsub(/@prefix@/, prefix)
    end

    # General user's password
    def password
      @config.db_general_password
    end

    # Using the template in the YAML files, produces a .NET connect string
    def connect_code
      if @config.db_general_authmode == :winauth
        @config.db_connect_string_winauth.gsub(/@host@/, host).
            gsub(/@initialcatalog@/, name)
      else
        @config.db_connect_string_sqlauth.gsub(/@host@/, host).
            gsub(/@initialcatalog@/, name).
            gsub(/@user@/, user).
            gsub(/@password@/, @config.db_general_password)
      end
    end
  end
end

