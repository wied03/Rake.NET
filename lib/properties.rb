class Props
  attr_accessor :props
  private_class_method :new

  @@config = nil
  
  def Props.it
    @@config = new # fix this unless @@config
    @@config
  end

  def initialize
      default_props = YAML::load(File.read('local_properties_default.yml'))
      prop = 'local_properties.yml'
      FileUtils.touch prop unless File.exists? prop
      user_props = YAML::load(File.read(prop))
      @props = merge user_props, default_props
  end

  private

  def printhash(hash)
    hash.each_pair { |k, v| puts "Key = #{k}, Value= #{v}" }
  end

  def merge(user, default)
    if !user
      puts "user is nothing"
      return default
    end
    if !user.is_a?(Hash)
      puts "and we're spent"
      return user
    end
    puts "Default Hash"
    printhash(default)
    puts "User Hash"
    printhash(user)
    merged = {}
	default.each do |key, defaultvalue|
		if user.has_key? key
            userval = user[key]
            puts "yes user value, for result key #{key} merging #{userval} with #{defaultvalue}"
			merged[key] = merge(userval, defaultvalue)
        else
            puts "no user value, setting result key #{key} to #{defaultvalue}"
            merged[key] = defaultvalue
		end
	end
	merged
  end
end
