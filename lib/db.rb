require 'socket'
require 'config'

module BradyW

  # Retrieves database related settings from our YAML configuration files
  class DB

    def initialize
      @props = BradyW::Config.Props
    end

    private

    def prefix
      @props['project']['prefix']
    end

    public

    CREDENTIALS = [:system, :objectcreation, :general]

    # Our db: props from the config file
    def dbprops
      @props['db']
    end

    # The hostname where the database lives (db: => hostname:)
    def host
      dbprops['hostname']
    end

    # The name of the database/catalog  (db: => name:)
    def name
      dbprops['name'].gsub(/@thismachinehostname@/, Socket.gethostname).
                      gsub(/@prefix@/, prefix)
    end

    # General user's username
    def user
      dbprops[:general.to_s]['user'].gsub(/@thismachinehostname@/, Socket.gethostname).
                                     gsub(/@prefix@/, prefix)
    end

    # General user's password
    def password
      dbprops[:general.to_s]['password']
    end

    def general
      dbprops[:general.to_s]
    end

    # Using the template in the YAML files, produces a .NET connect string
    def connect_code
      connects = dbprops['connect-strings']
      props = dbprops[:general.to_s]
      if props['mode'] == "winauth"
        connects['winauth'].gsub(/@host@/, host).
                            gsub(/@initialcatalog@/, name)
      else
        connects['sqlauth'].gsub(/@host@/, host).
                            gsub(/@initialcatalog@/, name).
                            gsub(/@user@/, user).
                            gsub(/@password@/, props['password'])
      end
    end
  end
end

