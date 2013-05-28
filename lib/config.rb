require "build_config"

module BradyW
  # Using the bwbuildconfig GEM, does a singleton fetch of properties from the YAML config files
  class Config
    private_class_method :new

    @@props = nil

    # Retrieve (using lazy instantation) our properties
    def Config.props
      @@props = BradyW::BuildConfig.new.props unless @@props
      @@props
    end
  end
end