$: << File.expand_path(File.dirname(__FILE__) +"/../lib")
require "rspec"
# Needed to mock out our config/props
require 'config'
require "singleton"

include FileUtils

RSpec.configure do |config|

  # File dependent tests, so we always baseline ourselves in the test directory
  config.before(:all) do
    @current = pwd
    cd File.expand_path(File.dirname(__FILE__))
  end

  config.after(:all) do
    cd @current
  end

  config.before(:each) do
    @config = BradyW::BaseConfig.new
    class MockConfig
      include Singleton
      attr_accessor :values
    end

    # Force only our base class to be returned
    BradyW::Config.stub!(:instance).and_return(MockConfig.instance)
    MockConfig.instance.values = @config
  end
end
