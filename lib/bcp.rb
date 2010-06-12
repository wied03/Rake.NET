require 'basetask'
require 'fastercsv'
require 'windowspaths'
require 'db'

module BW
	class BCP < BaseTask
		attr_accessor :delimiter, :files, :version
		include WindowsPaths

        def initialize (parameters = :task)
          super parameters
          @dbprops = DB.new
        end

		private

		def exectask
			# use the registry to figure out where the SQL Server binaries are (less configuration)
			tmp = "#{ENV['tmp']}/bcp"
			rm_rf(tmp)
			mkdir(tmp)
			
			puts "Using #{tmp} as a temp directory"
			
			files.each do |csv|
				currentdir = pwd
				fileName = File.basename(csv)
				csvtoCustomDelim csv, "#{tmp}/#{fileName}"
				cd tmp
				# need to trim off both the extension and the leading 2 numbers/hyphen
				sequenceAndTable = File.basename(csv, ".csv")				
				tableName = sequenceAndTable.match(/\d+-(.*)/)[1]				
				args = "\"#{prefix}#{tableName}\" in #{fileName} #{connect_string} -t \"#{delimiter}\" /c -m 1 -F 2"
				shell "\"#{path}bcp.exe\" " + args
				cd currentdir				
			end
			
			rm_rf(tmp)
			
			# convert to temporary delimited files
			# take the file, get the filename w/o path, trim off the extension to get the table name			
		end
		
		def csvtoCustomDelim(oldfile, newfile)
			File.open(newfile, "a") do |file|
              FasterCSV.foreach(oldfile) do |row|
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
          if @dbprops.dbprops['use']['mode'] == "winauth"
              "%s.dbo." % [@dbprops.name]
          else
              ""
          end
      end


      def connect_string
        if @dbprops.dbprops['use']['mode'] == "winauth"
            "-T -S %s" % [@dbprops.host]
        else
            "-U %s -P %s /S%s" % [@dbprops.user,
                                  @dbprops.dbprops['use']['password'],
                                  @dbprops.host]
        end
      end
	end
end