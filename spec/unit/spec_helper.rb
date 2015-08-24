require 'rspec/expectations'
# Needed to mock out our config/props
require 'rakedotnet'
require 'task_helper'
require 'io_helper'
require 'config_helper'

include FileUtils

RSpec.configure do |c|
  c.around do |example|
    # File dependent tests, so we always baseline ourselves in the test's directory
    Dir.chdir File.expand_path(File.dirname(example.metadata[:file_path])) do
      example.run
    end
  end
end
