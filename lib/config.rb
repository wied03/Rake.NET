require "base_config"

module BradyW
  # Using the bwbuildconfig GEM, does a singleton fetch of properties from the YAML config files
  class Config
    attr_accessor :currentConfiguration

    @@activeConfiguration = Config.new
    private_class_method :new

    # Retrieve (using lazy instantation) our properties
    def self.activeConfiguration
      @@activeConfiguration
    end

    def initialize(defaultfile = "local_properties_default.rb",
                   userfile = "local_properties.rb")
      puts "Using props file #{defaultfile} for default values"
      require defaultfile
      begin
        puts "Attempting to use props file #{userfile} for user/environment values"
        require userfile
      rescue LoadError
        puts "No user config file available"
      end
      configclass = BaseConfig.subclasses[-1]
      puts "Using configuration class: #{configclass.name}"
      @currentConfiguration = configclass.new
    end
  end
end