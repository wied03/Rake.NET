require 'rake'
require 'rake/tasklib'

module BW
	class BaseTask < Rake::TaskLib
		attr_accessor :name, :unless	
		
		def initialize(parameters = :task)
			parseParams parameters
			yield self if block_given?
			task @name => @dependencies if @dependencies unless @unless	
			define
		end

        private
        
		def parseParams parameters 
			@name = case parameters
						when Hash
							n = parameters.keys[0]
							@dependencies = parameters[n]
							n
						else
							parameters
					end		
		end
    
		# Create the tasks defined by this task lib.
		def define
			task name do
				if not @unless
					log "Running task: #{@name}"
					exectask
				else
					log "Skipping task: #{@name} due to unless condition specified in rakefile"
				end
			end
			self
        end

      def log text
        puts text
      end
	end
end