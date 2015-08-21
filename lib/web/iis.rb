require_relative '../basetask'

module BradyW

    # A task for starting/stopping IIS.  The task will not fail if the service cannot be stopped
    # successfully to avoid failing the build if IIS is already running.
	class IIS < BaseTask

        # *Required* Command to execute, should be either :start or :stop
		attr_accessor :command

        # *Optional* Service to bounce, by default W3SVC will be bounced.
        attr_accessor :service

        private

		# Create the tasks defined by this task lib.
		def exectask
            raise 'You forgot to supply a service command (:start, :stop)' unless @command
			puts 'Starting/Stopping IIS Service'
			cmd = "net.exe #{@command} #{service}"
			shell cmd do |ok,status|
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
          @service || 'W3SVC'
		end
	end
end
