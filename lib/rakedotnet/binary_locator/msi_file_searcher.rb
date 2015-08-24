require 'win32ole'

module BradyW
  class MsiFileSearcher
    def get_component_path(product_code,component_code)
    	installer = WIN32OLE.new('WindowsInstaller.Installer')
    	installer.ComponentPath product_code, component_code
    end
  end
end