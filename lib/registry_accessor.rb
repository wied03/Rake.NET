require 'win32/registry'

module BradyW
  class RegistryAccessor
    def reg_value(key, value)
      val = nil
      reg_key(key) do |reg|
        val = reg[value]
      end
      val
    end

    def sub_keys(key)
      keys = nil
      reg_key(key) do |reg|
        keys = reg.keys
      end
      keys
    end

    private

    def reg_key(key)
      begin
        reg_key_64(key) do |reg|
          yield reg
        end
        return
      rescue
        begin
          reg_key_32(key) do |reg|
            yield reg
          end
        rescue
          raise "Unable to find registry key: #{key}"
        end
      end
    end

    def reg_key_64(key)
      # workaround to make sure we have 64 bit registry access
      ourKeyRead = Win32::Registry::Constants::KEY_READ |
          Windows::Registry::KEY_WOW64_64KEY
      Win32::Registry.open(Win32::Registry::HKEY_LOCAL_MACHINE,
                           key,
                           ourKeyRead) do |reg|
        yield reg
      end
    end

    def reg_key_32(key)
      Win32::Registry.open(Win32::Registry::HKEY_LOCAL_MACHINE,
                           key) do |reg|
        yield reg
      end
    end
  end
end