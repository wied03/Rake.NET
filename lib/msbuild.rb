require 'basetask'
require 'windowspaths'

module BW

    # Launches a build using MSBuild
	class MSBuild < BaseTask
        DOTNET4_REG_PATH = "v4\\Client"
        DOTNET35_REGPATH = "v3.5"
        DOTNET2_HARDCODEDPATH = "C:\\Windows\\Microsoft.NET\\Framework\\v2.0.50727\\"
        include WindowsPaths

        # *Optional* Targets to build
		attr_accessor :targets

        # *Optional* Version of the MSBuild binary to use. Defaults to :v4
        # Other options are :v2 or :v3_5
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
          symbol = @dotnet_bin_version || :v4
          case symbol
            when :v4
              dotnet DOTNET4_REG_PATH
            when :v3_5
              dotnet DOTNET35_REGPATH
            when :v2
              DOTNET2_HARDCODEDPATH
          end
        end
	end
end