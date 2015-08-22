module BradyW
  class BaseConfig
    def self.subclasses
      ObjectSpace.each_object(Class).select { |k| k.ancestors.include?(self) and (k != self) }
      .sort_by { |k| k.name }
    end

    def project_prefix
      'BSW'
    end

    def db_hostname
      "localhost\\sqlexpress"
    end

    def db_name
      '@prefix@-@thismachinehostname@'
    end

    def db_object_creation_authmode
      :winauth
    end

    def db_object_creation_user
      'user'
    end

    def db_object_creation_password
      'password'
    end

    # winauth or sqlauth
    def db_general_authmode
      :sqlauth
    end

    def db_general_user
      db_name
    end

    def db_general_password
      'password'
    end

    def db_system_authmode
      :winauth
    end

    def db_system_user
      'user'
    end

    def db_system_password
      'password'
    end

    def db_system_datadir
      'D:/sqlserverdata'
    end

    def db_connect_string_winauth
      'Data Source=@host@;Initial Catalog=@initialcatalog@;Persist Security Info=True;Min Pool Size=20;Max Pool Size=500;Connection Timeout=15;Trusted_Connection=Yes'
    end

    def db_connect_string_sqlauth
      'Data Source=@host@;Initial Catalog=@initialcatalog@;Persist Security Info=True;User ID=@user@;Password=@password@;Min Pool Size=20;Max Pool Size=500;Connection Timeout=15;'
    end

    def build_type
      :Debug
    end

    def test_javascript_port
      9876
    end

    def test_javascript_browsers
      ['D:/Program Files/Mozilla Firefox/firefox.exe',
       'C:/Users/brady/AppData/Local/Google/Chrome/Application/chrome.exe']
    end

  end
end
