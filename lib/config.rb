require "base_config"

module BradyW
  # Using the bwbuildconfig GEM, does a singleton fetch of properties from the YAML config files
  class Config
    attr_accessor :props
    private_class_method :new

    @@props = nil

    # Retrieve (using lazy instantation) our properties
    def Config.props
      @@props = BradyW::BuildConfig.new.props unless @@props
      @@props
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
      @props = configclass.new
    end
  end
end