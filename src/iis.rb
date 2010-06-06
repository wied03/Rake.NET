require 'bwbuild/basetask'

module BW
	class Iis < BaseTask
		attr_accessor :command		
		
		def service
			if @service
				@service
			else
				"W3SVC";
			end
		end
    
		# Create the tasks defined by this task lib.
		def exectask
			puts "Starting/Stopping IIS Service"
			cmd = "net.exe #{@command} #{service}"
			puts cmd
			sh cmd, :verbose => false do |ok,status|
				ok or
				if @command == "STOP"
					puts "Ignoring failure since we're stopping"
					ok
				else			
					fail "Command failed with status (#{status.exitstatus}):"
				end
			end		
		end
	end
end