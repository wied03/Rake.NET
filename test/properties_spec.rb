require "spec"
require "../lib/yaml_config"
require 'rake'

module BW
  class YAMLConfig
    def YAMLConfig.reset
      @@instance = nil
    end
  end
end

describe "Properties" do
  before(:each) do
    @current = pwd
    BW::YAMLConfig.reset
  end

  after(:each) do
    rm "local_properties.yml" if @removegen
    cd @current
  end

  it "Should work OK with only default properties" do
    cd "properties/onlydefault"
    @removegen = true
    props = BW::YAMLConfig.Items
    props['area1']['setting'].should == "yep"
    props['area1']['setting2'].should == "nope"
    props['area2']['setting3'].should == "yep"
  end

  it "Should work OK with default + partially filled out user properties" do
    cd "properties/defaultpartialuser"
    props = BW::YAMLConfig.Items
    props['area1']['setting'].should == "overrodethis"
    props['area1']['setting2'].should == "nope"
    props['area2']['setting3'].should == "yep"
  end

  it "Should work OK with default + completely filled out user properties" do
    cd "properties/defaultanduser"
    props = BW::YAMLConfig.Items
    props['area1']['setting'].should == "yep2"
    props['area1']['setting2'].should == "nope2"
    props['area2']['setting3'].should == "yep2"
  end
end