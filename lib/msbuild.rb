require 'basetask'
require 'windowspaths'

module BW

    # Launches a build using MSBuild
	class MSBuild < BaseTask
        include WindowsPaths

        # *Optional* Targets to build
		attr_accessor :targets

        # *Optional* Version of the MSBuild binary to use. Defaults to "4.0"
        attr_accessor :dotnet_bin_version

        # *Optional* Solution file to build
        attr_accessor :solution

        # *Optional* .NET compilation version (what should MSBuild compile code to, NOT what version
        # of MSBuild to use).  Defaults to "4.0"
        attr_accessor :compile_version

        # *Optional* Properties to pass along to MSBuild.  By default 'Configuration' and
        # 'TargetFrameworkVersion' will be set based on the other attributes of this class.
        attr_accessor :properties

        # *Optional* Do a release build?  By default, this is false.
        attr_accessor :release

        private
        
		def exectask
			shell "#{path}msbuild.exe#{targets}#{propstr}#{solution}"
		end
		
		def compile
			@compile_version ? "v#{@compile_version}" : "v4.0"
        end

        def solution
          if @solution
            " " + @solution
          end
        end
		
		def targets
			if @targets
				" /target:#{@targets.join(",")}"
			end
		end
		
		def debugOrRelease
			@release ? "Release" : "Debug"
		end

        def propsmerged
          default = {}
		  default['Configuration'] = debugOrRelease
		  default['TargetFrameworkVersion'] = compile
          default.merge @properties || {}
        end

		def propstr
			keyvalue = []			
			propsmerged.each do |prop, set|
				keyvalue << "#{prop}=#{set}"
			end
			" /property:"+keyvalue.join(";")
		end		
		
		def path
          ver = @dotnet_bin_version || "4.0"
		  dotnet ver
		end
	end
end