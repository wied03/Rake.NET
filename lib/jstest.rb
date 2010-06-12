require 'basetask'
require 'yaml'

module BW
  class JsTest < BaseTask   
    attr_accessor :browsers, :version, :testoutput, :jarpath, :port, :files, :server
    
    private
    def exectask
		genConfigFile
		shell "java -jar #{jarpath}jsTestDriver-#{version}.jar --port #{port} --browser #{browsers} --tests all#{testoutput}"
		rm_rf configFile
    end
	
	def genConfigFile
        # This will include internal Rake FileList exclusion stuff if we don't do this
        onlyFiles = []
        @files.each { |f| onlyFiles << f}
		config = {"server" => "http://#{server}:#{port}",
				  "load" => onlyFiles}
		File.open configFile, 'w' do |file|
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