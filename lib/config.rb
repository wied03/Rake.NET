require "yaml_config"

module BW
  class Config
    private_class_method :new

    @@props = nil
    
    def Config.Props
      @@props = BW::YAMLConfig.new.props unless @@props
      @@props
    end
  end
end