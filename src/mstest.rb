require 'bwbuild/windowspaths'

module BW
	class MSTest < BaseTask
		include BW::WindowsPaths
		attr_accessor :files, :version

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