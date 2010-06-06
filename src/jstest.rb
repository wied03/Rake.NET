require 'bwbuild/basetask'
require 'yaml'

module BW
  class JsTest < BaseTask   
    attr_accessor :browsers, :version, :testoutput, :path, :port, :jspath
    
    # Create the tasks defined by this task lib.
    def exectask
		puts "Google JS Test Run"
		genConfigFile
		sh2 "java -jar #{path}jsTestDriver-#{version}.jar --port #{port} --browser #{browsers} --tests all"
		rm configFile
    end
	
	def genConfigFile
		config = ["server" => "http://localhost:#{port}",
				  "load" => @jspath]
		File.open (configFile, 'w') do |out|
			YAML.dump config, out
		end
	end
	
	def configFile
		"jsTestDriver.conf"
	end
	
	def browsers
		@browsers.join(",")
	end
	
	def version
		if @version
			@version
		else
			"1.2.1"
		end
	end
	
	def path
		if @path
			@path
		else
			"bwbuild/lib/"
		end
	end
	
	def port
		if @port
			@port
		else
			"9876"
		end
	end
  end
end