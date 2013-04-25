require 'basetask'
require 'windowspaths'
require 'db'

module BradyW

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

    # *Optional* By default, several variables are passed into SQLCMD based on the config file.
    # Add yours in here as key value pairs if you want to send more.
    # The following will be set by default:
    # * dbname - all credentials
    # * sqlserverdatadirectory - only when using :system credentials
    # * dbuser -> general user, all credentials
    # * dbpassword - > general password, only when using :system credentials
    attr_accessor :variables

    # *Optional* Setting this to true will NOT execute sqlcmd at all, but instead will go through
    # the source files supplied and replace any hard coded host names, database names, or any other
    # variables with sqlcmd style $(variable)s to make scripts more dynamic.  It's useful when
    # taking scripts creating on a single developer machine and prepping them for checkin.
    # Default is false.
    attr_accessor :makedynamic    

    # *Optional* Which set of DB credentials should be used?
    # :system - for creation/deletion of databases
    # :objectcreation - for adding/creating objects within a database
    # :general - DEFAULT - for adding/deleting rows within a database (use this for code)
    def credentials=(value)
      BaseTask.validate value, "credentials", DB::CREDENTIALS
      @credentials = value
    end

    def credentials
      @credentials || :general
    end

    private

    def credentialsString
      credentials.to_s
    end

    HEADER = "-- *************************************************************"
    CONNECT_STRING_WINAUTH = "-E -S %s"
    CONNECT_STRING_SQLAUTH = "-U %s -P %s -S %s"

    def initialize (parameters = :task)
      super parameters
      @dbprops = DB.new
      # We don't want the temp file/time changing on us during the run
      @tempfile = Sqlcmd.generatetempfilename
    end

    def exectask
      if makedynamic
        processdynamic
        return
      end
      
      createtempfile
      exe = "\"#{path}sqlcmd.exe\""
      args = "#{connect} -e -b#{variables_flat} -i #{@tempfile}"
      cmd = "#{exe} #{args}"
      shell cmd do |ok,status|
        # We want to clean up our temp file in case we fail
        removetempfile
        ok or
        fail "Command failed with status (#{status.exitstatus}):"
	  end
    end

    def processdynamic
       vars = variables
       @files.each do |fileName|
         next if File.directory? fileName
         text = File.read(fileName)
         vars.each do |setting,value|
           text.gsub!(value,
                      "$(#{setting})")
         end
         File.open fileName, "w" do |newFile|
            newFile.puts text
         end
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
        file.puts

        @files.each do |input|
          if File.directory? input
            containingdir = Sqlcmd.getdir input

            file.puts
            file.puts
            file.puts HEADER
            file.puts "-- Directory: #{containingdir}..."
            file.puts HEADER
            file.puts
            file.puts

          else
            file.puts "-- Script: #{input}"
            file.puts ":r #{input}"
          end
        end

        file.puts
        file.puts
        file.puts
        file.puts HEADER
        file.puts "-- COMPLETED BATCH SQL RUN"
        file.puts HEADER
      end
    end

    def removetempfile
      rm_safe @tempfile
    end

    def Sqlcmd.generatetempfilename
      "sqlload_"+DateTime.now.strftime("%Y%m%d%H%M%S") +".sql"
    end

    def path
      p = @version || "100"
      sql_tool p
    end

    def connect
      props = @dbprops.dbprops[credentialsString]
      if props['mode'] == "winauth"
            CONNECT_STRING_WINAUTH % [@dbprops.host]
        else
            CONNECT_STRING_SQLAUTH % [props["user"],
                                      props['password'],
                                      @dbprops.host]
      end
    end   

    def variables_flat
      keyvalue = []
      variables.each do |variable, setting|
        setting = setting.include?(' ') ? "\"#{setting}\"" : setting
        keyvalue << "#{variable}=#{setting}"  
      end
      " -v " + keyvalue.join(" ") unless variables.empty?
    end

    def variables
      # when we have usernames in SQL scripts, we're probably granting to a general purpose user, so that's why
      # we use gen and not something else
      default =
        {'dbname' => @dbprops.name,
         'dbuser' => @dbprops.user}

      if (credentials == :system || makedynamic)
        default['sqlserverdatadirectory'] = "\"#{@dbprops.dbprops[:system.to_s]['data-dir']}\""
        default['dbpassword'] = @dbprops.password
      end

      default.merge @variables || {}
    end
  end
end