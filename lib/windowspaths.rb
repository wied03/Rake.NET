require 'registry_accessor'

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
          def dotnet subpath
              regvalue "SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\#{subpath}", "InstallPath"
          end

          def regvalue(key, value)
              keyAndVal = "#{key}\\#{value}"
              log "Retrieving registry key #{keyAndVal}"
              regacc = BW::RegistryAccessor.new
              regacc.regvalue(key,value)
          end
	end
end