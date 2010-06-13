require 'windowspaths'

module BW
    # Runs MSTest tests using Visual Studio's MSTest runner
	class MSTest < BaseTask
		include BW::WindowsPaths

        # *Required* Files/test containers to test
		attr_accessor :files

        # *Optional* Version of Visual Studio/MSTest to use, defaults to 10.0 
        attr_accessor :version

        private
        
		def exectask
			@path = visual_studio_path
			sh2 "\"#{@path}MSTest.exe\"#{testcontainers}"
		end
		
		def testcontainers
			specifier = " /testcontainer:"
			mainstr = files.join(specifier)
			specifier+mainstr
		end
		
		def version
			if @version
				@version
			else
				"10.0"
			end
		end
	end
end