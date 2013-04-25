require 'basetask'
require 'windowspaths'
require 'db'
require 'csv'

module BW
=begin rdoc
Supports using Microsoft BCP to load CSV data.  Unlike BCP out of the box, this task attempts
to "support" comma escaping by converting your CSV files to files with an odd delimiter before
loading them in with BCP.
=end
	class BCP < BaseTask

        # *Optional* If the delimiter exists in your code (the task will fail if it does),
        # you need to change this attribute.
		attr_accessor :delimiter

#       *Required* Supply the files you wish to load into your tables here.  They should be named
#       using the following pattern SEQUENCE-TABLENAME.csv
#       Example:
#          01-users.csv
#          02-accounts.csv
#
#          OR
#          001-users.csv
#          002-accounts.csv

        attr_accessor :files
      
#      *Optional* By default, this looks for your installed version of BCP with SQL Server 2008.
#      If you're using SQL Server 2005, set this to "90"
        attr_accessor :version

        # *Optional* If this is set to true, then BCP's "-E" command line argument will be used.  If you
        # have primary keys in your files you wish to preserve, set this to true.  Default is false.
        attr_accessor :identity_inserts
      
		include WindowsPaths


		private

          def initialize (parameters = :task)
            super parameters
            @dbprops = DB.new
            tmpDir = ENV['TMP'] || '/tmp'
            @tmp = "#{tmpDir}/bcp"
          end

          def create_temp
            rm_safe @tmp
            mkdir @tmp
          end

          def exectask
                create_temp
                puts "Using #{@tmp} as a temp directory"

                files.each do |csv|
                    currentdir = pwd
                    fileName = File.basename csv
                    csvtoCustomDelim csv, "#{@tmp}/#{fileName}"
                    cd @tmp
                    # need to trim off both the extension and the leading 2 numbers/hyphen
                    sequenceAndTable = File.basename(csv, ".csv")
                    tableName = sequenceAndTable.match(/\d+-(.*)/)[1]
                    args = "\"#{prefix}#{tableName}\" in #{fileName} #{connect_string} -t \"#{delimiter}\" /c #{identity_inserts}-m 1 -F 2"

                    shell "\"#{path}bcp.exe\" #{args}" do |ok,status|
                      if !ok
                        cd currentdir
                        # We want to clean up our temp files if we fail
                        rm_safe @tmp
                        fail "Command failed with status (#{status.exitstatus}):"
                      end
                    end

                    cd currentdir
                end
                rm_safe @tmp
            end

            def csvtoCustomDelim(oldfile, newfile)              
                File.open(newfile, "a") do |file|
                  CSV.foreach(oldfile) do |row|
                      d = delimiter
                      row.each { |f| if f.include? d
                                          puts "Your data contains the crazy delimiter that's currently configured, which is "
                                          puts "#{d} "
                                          puts " (the default one) " unless !d
                                          puts "Pass in the 'delimiter' attribute from your rakefile with a different random value."
                                          puts "Hopefully then it will not exist in your data and can be used with bcp to import"
                                          puts "data into the database."
                                          fail
                                     end}
                      newRow = row.join(d)
                      file.puts newRow
                  end
                end
            end

            def path
              p = @version || "100"
              sql_tool p
            end

            def delimiter
              @delimiter || "|d3l1m1t3r|"
            end

          # BCP doesn't allow initial catalogs for SQL auth, but does for winauth and we need them
          # since winauth users might use several schemas
          def prefix
              if @dbprops.general['mode'] == "winauth"
                  "%s.dbo." % [@dbprops.name]
              else
                  ""
              end
          end

          def identity_inserts
            @identity_inserts ? "-E " : ""
          end

          def connect_string
            gen = @dbprops.general
            if gen['mode'] == "winauth"
                "-T -S %s" % [@dbprops.host]
            else
                "-U %s -P %s /S%s" % [@dbprops.user,
                                      @dbprops.password,
                                      @dbprops.host]
            end
          end
	end
end