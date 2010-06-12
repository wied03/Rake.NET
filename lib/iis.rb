require 'basetask'

module BW
	class IIS < BaseTask
		attr_accessor :command, :service		

        private
    
		# Create the tasks defined by this task lib.
		def exectask
            raise "You forgot to supply a service command (:start, :stop)" unless @command 
			puts "Starting/Stopping IIS Service"
			cmd = "net.exe #{@command} #{service}"
			puts cmd
			sh cmd do |ok,status|
				ok or
				if @command == :stop
					puts "Ignoring failure since we're stopping"
					ok
				else			
					fail "Command failed with status (#{status.exitstatus}):"
				end
			end		
        end

        def service
          @service || "W3SVC"
		end
	end
end