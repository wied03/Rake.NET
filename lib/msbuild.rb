require 'basetask'
require 'windowspaths'

module BW
	class MSBuild < BaseTask
        include WindowsPaths
        
		attr_accessor :targets, :dotnet_bin_version, :solution, :compile_version, :properties, :release

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
		
		def propstr
			@properties = {} unless @properties
			@properties['Configuration'] = debugOrRelease
			@properties['TargetFrameworkVersion'] = compile
			keyvalue = []			
			@properties.each do |prop, set|
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