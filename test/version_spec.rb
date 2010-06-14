require "base"
require "version"

describe "Version Incrementer" do
  after(:each) do
    FileUtils::rm_rf "VERSION.yml"    
  end
  
  it "Should work OK with a new file" do
    result = BW::Version.incrementandretrieve
    result.should == "1.0.0"
  end

  it "Should work OK with an existing file" do
    File.open "VERSION.yml", 'w' do |file|
        config =  {"version" => "1.0.1"}
	    YAML.dump config, file
	end
    result = BW::Version.incrementandretrieve
    result.should == "1.0.2"

    expected = IO.readlines("data/version/expected.yml")
    actual = IO.readlines("VERSION.yml")
    actual.should == expected
  end
end