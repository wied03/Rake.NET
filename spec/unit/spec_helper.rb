require 'rspec/expectations'
# Needed to mock out our config/props
require 'rakedotnet'
require 'task_helper'
require 'io_helper'
require 'config_helper'

include FileUtils

RSpec.configure do |c|
  # File dependent tests, so we always baseline ourselves in the test directory
  c.before :all do
    @current = pwd
    cd File.expand_path(File.dirname(__FILE__))
  end

  c.after :all do
    cd @current
  end
end
