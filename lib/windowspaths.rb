require 'registry_accessor'

module BradyW
  module WindowsPaths
    private
    # Fetches the path for tools like bcp.exe and sqlcmd.exe from the registry
    def sql_tool version
      reg_value "SOFTWARE\\Microsoft\\Microsoft SQL Server\\#{version}\\Tools\\ClientSetup", 'Path'
    end

    # Fetches the path for Visual Studio tools like MSTest.exe from the registry
    def visual_studio version
      reg_value "SOFTWARE\\Microsoft\\VisualStudio\\#{version}", 'InstallDir'
    end

    # Fetches the .NET Framework path from the registry
    def dotnet subpath
      reg_value "SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\#{subpath}", 'InstallPath'
    end

    def reg_value(key, value)
      keyAndVal = "#{key}\\#{value}"
      log "Retrieving registry key #{keyAndVal}"
      accessor = BradyW::RegistryAccessor.new
      accessor.get_value(key, value)
    end
  end
end