$: << File.expand_path(File.dirname(__FILE__) +"/../lib")
require 'rspec/expectations'
# Needed to mock out our config/props
require 'config'
require 'singleton'
require 'basetask'
require 'basetaskmocking'

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
    BradyW::BaseTask.clear_shell_stack
    @config = BradyW::BaseConfig.new
    class MockConfig
      include Singleton
      attr_accessor :values
    end

    # Force only our base class to be returned
    BradyW::Config.stub(:instance).and_return(MockConfig.instance)
    MockConfig.instance.values = @config
  end
end


def simulate_redirected_log_output(task, options)
  # STDOUT redirects on Windows seem to come back like this
  options = {:file_write_options => 'w:UTF-16LE:ascii', :failure_return_code => false}.merge(options.is_a?(Hash) ? options : {:file_name => options})
  task.stub(:shell) { |*commands, &block|
    # Simulate dotNetInstaller logging to the file
    File.open options[:file_name], options[:file_write_options] do |writer|
      yield writer
    end
    puts commands
    @commands = commands
    failure = options[:failure_return_code] ? SimulateProcessFailure.new : nil
    block.call(nil, failure) if block
  }
end

