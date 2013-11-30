require 'win32/registry'
require 'windows/registry'

module BradyW
  class RegistryAccessor
    def get_value(key, value)
      val = nil
      reg_key(key) do |reg|
        val = reg[value]
      end
      val
    end

    def get_sub_keys(key)
      keys = []
      reg_key(key) do |reg|
        keys += reg.keys
      end
      keys.uniq
    end

    private

    def reg_key(key, &block)
      begin
        reg_key_64(key, &block)
        # Try and get a 32 bit value as well in case merging needs to be done
        begin
          reg_key_32(key, &block)
        rescue
          # No problem, we already succeeded in getting a 64 bit value
        end
      rescue
        begin
          reg_key_32(key, &block)
        rescue Exception => e
          raise "Unable to find registry key: #{key}" if e.message == 'The system cannot find the file specified.'
          raise e
        end
      end
    end

    def reg_key_64(key)
      # workaround to make sure we have 64 bit registry access
      reg_type = Win32::Registry::KEY_READ | Windows::Registry::KEY_WOW64_64KEY
      Win32::Registry::HKEY_LOCAL_MACHINE.open(key,
                                               reg_type) do |reg|
        yield reg
      end
    end

    def reg_key_32(key)
      Win32::Registry::HKEY_LOCAL_MACHINE.open(key) do |reg|
        yield reg
      end
    end
  end
end