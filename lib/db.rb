require 'socket'
require 'config'

module BW

  # Retrieves database related settings from our YAML configuration files
  class DB

    def initialize
      @props = BW::Config.Props
    end

    private

      def prefix
        @props['project']['prefix']
      end      

    public

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

      # DB user to use when NOT creating the database (db: => use: => user:) 
      def user
          dbprops['use']['user'].gsub(/@thismachinehostname@/, Socket.gethostname).
                                      gsub(/@prefix@/, prefix)
      end

      # Using the template in the YAML files, produces a .NET connect string
      def connect_code
          prop = dbprops['connect-strings']
          if dbprops['use']['mode'] == "winauth"
              prop['winauth'].gsub(/@host@/,host).
                              gsub(/@initialcatalog@/, name)
          else
              prop['sqlauth'].gsub(/@host@/,host).
                              gsub(/@initialcatalog@/, name).
                              gsub(/@user@/, user).
                              gsub(/@password@/, dbprops['use']['password'])
          end
      end
  end
end

