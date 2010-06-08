require 'bwbuild/basetask'
require 'fastercsv'
require 'bwbuild/windowspaths'

module BW
	class BCP < BaseTask
		attr_accessor :prefix, :delimiter, :connect_string, :files, :version
		include BW::WindowsPaths
		
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
				args = "\"#{@prefix}#{tableName}\" in #{fileName} #{@connect_string} -t \"#{delimiter}\" /c -m 1 -F 2"
				sh2 "\"#{sql_tool_path}bcp.exe\" " + args				
				cd currentdir				
			end
			
			rm_rf(tmp)
			
			# convert to temporary delimited files
			# take the file, get the filename w/o path, trim off the extension to get the table name			
		end
		
		def csvtoCustomDelim(oldfile, newfile)
			file = File.open(newfile, "a")
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
			file.close
		end
		
		def version
			if @version
				@version
			else
				"100"
			end
		end
		
		def delimiter
			if @delimiter
				@default_delim = false
				@delimiter
			else
				@default_delim = true
				"|d3l1m1t3r|"
			end
        end

      # Prefix to use with BCP
      # BCP doesn't allow initial catalogs for SQL auth, but does for winauth and we need them
      # since winauth users might use several schemas
      def bcp_prefix
          if dbprops['use']['mode'] == "winauth"
              "%s.dbo." % [db_name]
          else
              ""
          end
      end


      def connect_bcp
        if dbprops['auth-windows-normal']
            "-T -S %s" % [host]
        else
            "-U %s -P %s /S%s" % [db_user,
                                  dbprops['password'],
                                  host]
        end
      end
	end
end