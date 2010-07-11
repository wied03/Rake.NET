require 'win32/registry'
require 'windows/registry'

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
              puts "Retrieving registry key #{key}\\#{value}"
              # workaround to make sure we have 64 bit registry access
              ourKeyRead = Win32::Registry::Constants::KEY_READ |
						   Windows::Registry::KEY_WOW64_64KEY
              Win32::Registry::HKEY_LOCAL_MACHINE.open(key, ourKeyRead) do |reg|
                  return reg[value]
              end
          end
	end
end