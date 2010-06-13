require "yaml_config"

module BW
  # Using the bwyamlconfig GEM, does a singleton fetch of properties from the YAML config files
  class Config
    private_class_method :new

    @@props = nil

    # Retrieve (using lazy instantation) our properties
    def Config.Props
      @@props = BW::YAMLConfig.new.props unless @@props
      @@props
    end
  end
end