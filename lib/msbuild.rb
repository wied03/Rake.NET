require 'basetask'
require 'windowspaths'

module BradyW

    # Launches a build using MSBuild
	class MSBuild < BaseTask
        include WindowsPaths

        # *Optional* Targets to build.  Can be a single target or an array of targets
		attr_accessor :targets

        # *Optional* Version of the MSBuild binary to use. Defaults to :v4_0
        # Other options are :v2_0 or :v3_5
        attr_accessor :dotnet_bin_version

        # *Optional* Solution file to build
        attr_accessor :solution

        # *Optional* .NET compilation version (what should MSBuild compile code to, NOT what version
        # of MSBuild to use).  Defaults to :v4_0).  Other options are :v2_0 or :v3_5
        attr_accessor :compile_version

        # *Optional* Properties to pass along to MSBuild.  By default 'Configuration' and
        # 'TargetFrameworkVersion' will be set based on the other attributes of this class.
        attr_accessor :properties

        # *Optional* Do a release build?  By default, this is false.
        attr_accessor :release

        private
        
        DOTNET4_REG_PATH = "v4\\Client"
        DOTNET35_REGPATH = "v3.5"
        DOTNET2_HARDCODEDPATH = "C:\\Windows\\Microsoft.NET\\Framework\\v2.0.50727\\"        
        
		def exectask
			shell "#{path}msbuild.exe#{targets}#{propstr}#{solution}"
		end
		
		def compile_version
            symbol =  @compile_version || :v4_0
            ver = convertToNumber symbol
			"v#{ver}"
        end

        def solution
          if @solution
            " " + @solution
          end
        end
		
		def targets
			if @targets
				" /target:#{flatTargets}"
			end
        end

        def flatTargets
          return nil unless @targets
          @targets.is_a?(Array) ? @targets.join(",") : @targets
        end
		
		def debugOrRelease
			@release ? "Release" : "Debug"
		end

        def propsmerged
          default = {}
		  default['Configuration'] = debugOrRelease
		  default['TargetFrameworkVersion'] = compile_version
          default.merge @properties || {}
        end

		def propstr
			keyvalue = []			
			propsmerged.each do |prop, set|
				keyvalue << "#{prop}=#{set}"
			end
			" /property:"+keyvalue.join(";")
        end

        def convertToNumber symbol
          trimmedV = symbol.to_s()[1..-1]
          trimmedV.gsub(/_/, '.')
        end

        def path
          symbol = @dotnet_bin_version || :v4_0
          case symbol
            when :v4_0
              dotnet DOTNET4_REG_PATH
            when :v3_5
              dotnet DOTNET35_REGPATH
            when :v2_0
              DOTNET2_HARDCODEDPATH
            else
              fail "You supplied a .NET MSBuild binary version that's not supported.  Please use :v4_0, :v3_5, or :v2_0"
          end
        end
	end
end