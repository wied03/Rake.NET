require 'win32/registry'

module BW
	module WindowsPaths
        private
        
        # Fetches the path for tools like bcp.exe and sqlcmd.exe from the registry
		def sql_tool version
			regvalue "SOFTWARE\\Microsoft\\Microsoft SQL Server\\#{version}\\Tools\\ClientSetup", 'Path'
		end

        # Fetches the path for Visual Studio tools like MSTest.exe from the registry
		def visual_studio version
			regvalue "SOFTWARE\\Microsoft\\VisualStudio\\#{version}", 'InstallDir'
        end

        # Fetches the .NET Framework path from the registry
        def dotnet version
            regvalue "SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v#{version}", "InstallPath"
        end
		
		def regvalue(key, value)		
			Win32::Registry::HKEY_LOCAL_MACHINE.open(key) do |reg|
				return reg[value]
			end
		end
	end
end