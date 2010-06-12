require 'basetask'
require 'windowspaths'
require 'db'

module BW
  class Sqlcmd < BaseTask
    include WindowsPaths

    attr_accessor :files, :version, :usecreatecredentials, :variables
    
    def initialize (parameters = :task)
          super parameters
          @dbprops = DB.new
    end

    private

    def exectask
      exe = "\"#{path}sqlcmd.exe\""
      args = "#{connect} -e #{variables_flat} -i #{tempfile}"
      sh2 "#{exe} #{args}"
    end

    def tempfile
      "sqlload_"+DateTime.now.strftime("%Y%m%d%H%M%S") +".sql"
    end

    def path
      p = @version || "100"
      sql_tool p
    end

    def creating
       @usecreatecredentials || false
    end

    def connect
      creating ? connect_create : connect_use
    end

    # Use this while creating tables/indexes/etc. (NOT creating a database)
    def connect_use
        if @dbprops.dbprops['use']['mode'] == "winauth"
            "-E -S %s" % [@dbprops.host]
        else
            "-U %s -P %s -S %s" % [@dbprops.user,
                                   @dbprops.dbprops['use']['password'],
                                   @dbprops.host]
        end
    end

    # Use this while creating a database
    def connect_create
        if @dbprops.dbprops['create']['mode'] == "winauth"
            "-E -S %s" % [@dbprops.host]
        else
            "-U %s -P %s -S %s" % [@dbprops.dbprops['create']['user'],
                                   @dbprops.dbprops['create']['password'],
                                   @dbprops.host]
        end
    end

    def variables_flat
      keyvalue = []
      variables.each do |variable, setting|
        keyvalue << "#{variable}=#{setting}"  
      end
      "-v " + keyvalue.join(" ")
    end

    def variables
        {'dbname' => @dbprops.name,
         'sqlserverdatadirectory' => "\"#{@dbprops.dbprops['use']['data-dir']}\"",
         'dbuser' => @dbprops.user,
         'dbpassword' => @dbprops.dbprops['use']['password']}
    end
  end
end