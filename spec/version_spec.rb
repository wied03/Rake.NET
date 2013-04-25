require "base"
require "version"

describe BW::Version do
  after(:each) do
    FileUtils::rm_rf "CURRENTVERSION.yml"
  end
  
  it "Should work OK with a new file" do
    result = BW::Version.incrementandretrieve
    result.should == "1.0.0"
  end

  it "Should work OK with an existing file" do
    File.open "CURRENTVERSION.yml", 'w' do |file|
        config =  {"version" => "1.0.1"}
	    YAML.dump config, file
	end
    result = BW::Version.incrementandretrieve
    result.should == "1.0.2"

    expected = IO.readlines("data/version/expected.yml")
    actual = IO.readlines("CURRENTVERSION.yml")
    actual.should == expected
  end
end