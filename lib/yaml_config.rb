module BW
  class YAMLConfig
    attr_accessor :props
    private_class_method :new

    @@instance = nil

    def YAMLConfig.singleton
      @@instance = new unless @@instance
      @@instance
    end

    def YAMLConfig.Items
      YAMLConfig.singleton.props
    end

    def initialize
        default_props = YAML::load(File.read('local_properties_default.yml'))
        prop = 'local_properties.yml'
        FileUtils.touch prop unless File.exists? prop
        user_props = YAML::load(File.read(prop))
        @props = merge user_props, default_props
    end

    private

    def merge(user, default)
      return default unless user
      return user unless user.is_a?(Hash)
      default.each do |key, defaultvalue|
          if user.has_key? key
              userval = user[key]
              user[key] = merge(userval, defaultvalue)
          else
              user[key] = defaultvalue
          end
      end
      user
    end
  end
end