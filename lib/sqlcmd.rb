require 'basetask'
require 'windowspaths'
require 'db'

module BW

  # Runs SQLcmd to run supplied SQL scripts.  This task will roll up all supplied SQL script files
  # into 1 SQL file before running it in order to speed up the tasks.  The "-e" flag is used so that
  # all statements are echo'ed to stdout.
  class Sqlcmd < BaseTask
    include WindowsPaths

    # *Required* Which SQL scripts do you want to run?  Everything in this path will be run with this script.
    # It's recommended that you arrange your structure like the one below.  If you do, the generated
    # meta script will have nice comments that indicate what it's currently running
    #  somedirectory
    #    01-tables
    #        01-table1.sql
    #        02-table2.sql
    #    02-indexes
    attr_accessor :files

    # *Optional* Version of SQL Server's sqlcmd to use.  Defaults to SQL Server 2008.  
    attr_accessor :version

    # *Optional* If you're creating a database, pass true in here to use the config file's creation
    # credentials instead of the regular credentials.  Defaults to false.
    attr_accessor :usecreatecredentials

    # *Optional* By default, several variables are passed into SQLCMD based on the config file.
    # Add yours in here as key value pairs if you want to send more.  Defaults:
    # * dbname
    # * sqlserverdatadirectory
    # * dbuser
    # * dbpassword
    attr_accessor :variables

    private

    HEADER = "-- *************************************************************"
    
    def initialize (parameters = :task)
      super parameters
      @dbprops = DB.new
      # We don't want the temp file/time changing on us during the run
      @tempfile = generatetempfilename
    end

    def exectask
      createtempfile
      exe = "\"#{path}sqlcmd.exe\""
      args = "#{connect} -e #{variables_flat} -i #{@tempfile}"
      cmd = "#{exe} #{args}"
      puts cmd
      shell cmd do |ok,status|
        # We want to clean up our temp file in case we fail
        removetempfile
        ok or
        fail "Command failed with status (#{status.exitstatus}):"
	  end
    end

    def Sqlcmd.getdir directory
      parentDir = File.dirname directory
      directory[parentDir.length+1..-1]
    end

    def createtempfile
      File.open(@tempfile, "w") do |file|
        file.puts HEADER
        file.puts "-- BEGIN BATCH SQL RUN"
        file.puts HEADER

        @files.each do |input|
          if File.directory? input
            containingdir = Sqlcmd.getdir input

            file.puts HEADER
            file.puts "-- Running #{containingdir}..."
            file.puts HEADER
          else
            file.puts ":r #{input}"
          end
        end

        file.puts HEADER
        file.puts "-- COMPLETED BATCH SQL RUN"
        file.puts HEADER
      end
    end

    def removetempfile
      rm_rf @tempfile
    end

    def Sqlcmd.generatetempfilename
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
      default =
        {'dbname' => @dbprops.name,
         'sqlserverdatadirectory' => "\"#{@dbprops.dbprops['use']['data-dir']}\"",
         'dbuser' => @dbprops.user,
         'dbpassword' => @dbprops.dbprops['use']['password']}

      default.merge @variables || {}
    end
  end
end