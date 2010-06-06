def load_properties
	defaultProps = YAML::load(File.read('local_properties_default.yml'))	
	prop = 'local_properties.yml'
	FileUtils.touch prop unless File.exists? prop
	userProps = YAML::load(File.read(prop))
	@props = merge userProps, defaultProps
end

def merge(user, default)
	return user if default.class != Hash or user.class != Hash
	default.each do |key, value|
		if !user.has_key? key
			user[key] = value
		else
			user[key] = merge(user[key], value)
		end
	end
	user
end

load_properties