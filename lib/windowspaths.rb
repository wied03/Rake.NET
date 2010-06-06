require 'win32/registry'

module BW
	module WindowsPaths
		def sql_tool_path
			regvalue "SOFTWARE\\Microsoft\\Microsoft SQL Server\\#{version}\\Tools\\ClientSetup", 'Path'
		end
		
		def visual_studio_path			
			regvalue "SOFTWARE\\Microsoft\\VisualStudio\\#{version}", 'InstallDir'
		end
		
		def regvalue(key, value)		
			Win32::Registry::HKEY_LOCAL_MACHINE.open(key) do |reg|
				return reg[value]
			end
		end
	end
end