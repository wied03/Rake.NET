require 'win32/registry'

module BradyW
  class RegistryAccessor
    def regvalue(key, value)
      keyAndVal = "#{key}\\#{value}"      
      begin
        regvalue64(key, value)
      rescue
        begin
          regvalue32(key, value)
        rescue
          raise "Unable to find registry value in either 32 or 64 bit mode: #{keyAndVal}"
        end
      end
    end

	private
	
    def regvalue64(key, value)
      # workaround to make sure we have 64 bit registry access
      ourKeyRead = Win32::Registry::Constants::KEY_READ |
                           Windows::Registry::KEY_WOW64_64KEY
      Win32::Registry.open(Win32::Registry::HKEY_LOCAL_MACHINE,
                           key,
                           ourKeyRead) do |reg|
        return reg[value]
      end
    end

    def regvalue32(key, value)
      Win32::Registry.open(Win32::Registry::HKEY_LOCAL_MACHINE,
                           key) do |reg|
        return reg[value]
      end
    end
  end
end