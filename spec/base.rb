$: << File.expand_path(File.dirname(__FILE__) +"/../lib")
require "rspec"
# Needed to mock out our config/props
require 'config'

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
    @props = {}
    BradyW::Config.stub!(:props).and_return(@props)
  end
end
