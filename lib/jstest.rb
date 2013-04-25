require 'basetask'
require 'yaml'

module BW
  # Executes Javascript tests using Google's JS Test.  By default, the task outputs test results in
  # plain text to stdout.
  class JsTest < BaseTask

    # *Required* Which Javascript files should be passed on to JS Test driver?
    attr_accessor :files
    
    # *Required* List of browser paths to run the test on. (surrounded in quotes on Windows)
    attr_accessor :browsers

    # *Optional* Google JS Test Driver in use (defaults to 1.2.1)
    attr_accessor :version

    # *Optional* If XML output is enabled, what directory should it go to (default is current)
    attr_accessor :outpath

    # *Optional* Should XML output be enabled?  By default the task looks for the CCNetProject environment
    # variable to decide this
    attr_accessor :xmloutput

    # Where is the Test driver JAR located (defaults to "lib/")
    attr_accessor :jarpath

    # *Optional* Which port should the Test Driver Server run on (defaults to 9876)
    attr_accessor :port

    # *Optional* Where should the server be running?  Default is localhost, which causes the server to launch
    # when this task is run.  If you specify another server here, then this task will NOT
    # launch a server and will instead only run the tests.
    attr_accessor :server
    
    private
    def exectask
		genConfigFile
		cmd = "java -jar #{jarpath}jsTestDriver-#{version}.jar#{portparam}#{browsers} --tests all#{testoutput}"
        shell cmd do |ok,status|
           # We want to clean up our temp file in case we fail
          rm_safe configFile
          ok or
          fail "Command failed with status (#{status.exitstatus}):"
        end		
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
      if xmloutput
        " --testOutput " + (@outpath || ".")
      end
    end

    def xmloutput
      @xmloutput || ENV["CCNetProject"]
    end
	
	def configFile
		"jsTestDriver.conf"
	end
	
	def browsers
		" --browser "+@browsers.join(",") unless @server
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


    def portparam
      " --port #{port}" unless @server
    end
    
	def port
      @port || "9876"
	end
  end
end