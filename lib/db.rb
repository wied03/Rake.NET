require 'socket'
require 'config'

module BW
  class DB
    def initialize
      @props = BW::Config.Props
    end

    private

      def prefix
        @props['project']['prefix']
      end

      def dbprops
        @props['db']
      end

    public

      # The hostname where the database lives
      def host
         dbprops['hostname']
      end

      # The name of the database/catalog
      def name
          dbprops['name'].gsub(/@thismachinehostname@/, Socket.gethostname).
                               gsub(/@prefix@/, prefix)    end

      # The name of the database user
      def user
          dbprops['use']['user'].gsub(/@thismachinehostname@/, Socket.gethostname).
                                      gsub(/@prefix@/, prefix)
      end

      # Connect string you should use in your .NET code
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

