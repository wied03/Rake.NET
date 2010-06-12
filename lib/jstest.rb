require 'basetask'
require 'yaml'

module BW
  class JsTest < BaseTask   
    attr_accessor :browsers, :version, :testoutput, :jarpath, :port, :files, :server
    
    private
    def exectask
		genConfigFile
		sh "java -jar #{jarpath}jsTestDriver-#{version}.jar --port #{port} --browser #{browsers} --tests all#{testoutput}"
		rm_rf configFile
    end
	
	def genConfigFile
		config = {"server" => "http://#{server}:#{port}",
				  "load" => @files}
		File.open (configFile, 'w') do |file|
			YAML.dump config, file
		end
    end

    def testoutput
      if ENV['CI']
        " --testOutput " + (@testoutput || ".")
      end
    end
	
	def configFile
		"jsTestDriver.conf"
	end
	
	def browsers
		@browsers.join(",")
	end
	
	def version
      @version || "1.2.1"
    end

    def server
      @server || "localhost"
    end
	
	def jarpath
      @jarpath || "lib/"
	end
	
	def port
      @port || "9876"
	end
  end
end