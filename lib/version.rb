require 'yaml'

module BW
  # Keeps track of package versions (1.0.x) using a YAML file
  class Version

    FILENAME = "VERSION.yml"

    # Increments and retrieves the current version
    def Version.incrementandretrieve
      current = YAML::load(File.read(FILENAME)) if File.exists? FILENAME
      if current
        sections = current["version"].split('.')
        subrelease = sections[sections.length-1].to_i
        sections[sections.length-1] = subrelease + 1
        version = sections.join('.')
      else
        version = "1.0.0"
      end
      
      File.open FILENAME, 'w' do |file|
        config =  {"version" => version}
	    YAML.dump config, file
      end

      version
    end
  end
end