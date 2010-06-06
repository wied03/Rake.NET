require 'rake'
require 'rake/tasklib'

module BW
	class BaseTask < Rake::TaskLib
		attr_accessor :name, :unless	
		
		def initialize(params=:task)
			parseParams(params)
			yield self if block_given?
			task @name => @dependencies if @dependencies unless @unless	
			define
		end
		
		def parseParams(hash)
			@name = case hash
						when Hash
							n = hash.keys[0]
							@dependencies = hash[n]
							n
						else
							hash
					end		
		end
    
		# Create the tasks defined by this task lib.
		def define
			task name do
				if not @unless
					puts "Running task #{@name}"
					exectask
				else
					puts "Skipping task: #{@name} due to unless condition specified in rakefile"
				end
			end
			self
		end
	end
end