require_relative 'registry_accessor'
require_relative 'msi_file_searcher'

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

    # Fetched the path of Subinacl 5.2.3790 if it's installed
    SUBINACL_PRODUCT_CODE = '{D3EE034D-5B92-4A55-AA02-2E6D0A6A96EE}'
    SUBINACL_EXE_COMPONENT_CODE = '{C2BC2826-FDDC-4A61-AA17-B3928B0EDA38}'

    def subinacl_path
      component_locator = BradyW::MsiFileSearcher.new
      component_locator.get_component_path SUBINACL_PRODUCT_CODE, SUBINACL_EXE_COMPONENT_CODE
    end

    def cmd_exe
      ENV['ComSpec']
    end

    def reg_value(key, value)
      keyAndVal = "#{key}\\#{value}"
      log "Retrieving registry key #{keyAndVal}"
      accessor = BradyW::RegistryAccessor.new
      accessor.get_value(key, value)
    end
  end
end