require 'basetask'
require 'windowspaths'

module BW
	class MSBuild < BaseTask
        include WindowsPaths
        
		attr_accessor :targets, :dotnet_bin_version, :solution, :compile_version, :properties, :release

        private
        
		def exectask
			sh2 "#{path}msbuild.exe#{targets}#{propstr}#{solution}"
		end
		
		def compile
			if @compile_version
				"v#{@compile_version}"
			else
				"v4.0"
			end
        end

        def solution
          if @solution
            " "+@solution
          end
        end
		
		def targets
			if @targets
				" /target:#{@targets.join(",")}"
			end
		end
		
		def debugOrRelease
			if @release
				"Release"
			else
				"Debug"
			end
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
			if @dotnet_bin_version
				dotnet @dotnet_bin_version
			else
				dotnet "4.0"
			end
		end
	end
end