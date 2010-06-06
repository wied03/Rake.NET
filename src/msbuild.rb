require 'bwbuild/basetask'

module BW
	class MSBuild < BaseTask
		attr_accessor :target, :dotnet_bin_version, :solution, :compile_version, :properties, :release
		def exectask
			sh2 "#{path}\\msbuild.exe /target:#{t} /property:#{propstr} #{@solution}"
		end
		
		def compile
			if @compile_version
				@compile_version
			else
				"v4.0"
			end
		end
		
		def t
			if @target
				@target
			else
				"build"
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
			keyvalue.join(";")
		end		
		
		def path
			if @dotnet_bin_version
				"C:\\Windows\\Microsoft.NET\\Framework\\v#{@dotnet_bin_version}"
			else
				"C:\\Windows\\Microsoft.NET\\Framework\\v4.0.21006"
			end
		end
	end
end