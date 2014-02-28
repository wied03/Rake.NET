require_relative 'base_config'
require 'singleton'

module BradyW
  # Using the bwbuildconfig GEM, does a singleton fetch of properties from the YAML config files
  class Config
    include Singleton
    attr_accessor :values

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
      @values = configclass.new
    end
  end
end