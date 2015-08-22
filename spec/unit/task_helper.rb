require 'singleton'
require 'basetaskmocking'

RSpec.shared_context :executable_test do
  let(:task_block) { lambda { |t|} }
  subject(:task) { described_class.new(&task_block) }

  module RegexStuff
    def get_executed(task)
      task.exectaskpublic
      task.executedPop
    end

    def get_exe_only(task)
      get_exe_from_executed(get_executed(task))
    end

    def get_exe_from_executed(command_line)
      /(.*exe[" ]).*/.match(command_line).captures[0].strip
    end

    def get_params_only(task)
      executed = get_executed task
      exe_portion = get_exe_from_executed executed
      executed.gsub(exe_portion, '').strip
    end
  end

  RSpec::Matchers.define :execute_bin do |matcher|
    include RegexStuff

    match do |task|
      actual = get_exe_only task
      matcher.matches? actual
    end

    failure_message do
      matcher.failure_message
    end
  end

  RSpec::Matchers.define :execute_with_params do |matcher|
    include RegexStuff

    match do |task|
      actual = get_params_only task
      matcher.matches? actual
    end

    failure_message do
      matcher.failure_message
    end
  end

  # File dependent tests, so we always baseline ourselves in the test directory
  before(:all) do
    @current = pwd
    cd File.expand_path(File.dirname(__FILE__))
  end

  after(:all) do
    cd @current
  end

  before do
    BradyW::BaseTask.clear_shell_stack
    @config = BradyW::BaseConfig.new
    class MockConfig
      include Singleton
      attr_accessor :values
    end

    # Force only our base class to be returned
    allow(BradyW::Config).to receive(:instance).and_return(MockConfig.instance)
    MockConfig.instance.values = @config
  end

  def read_file_in_bin_mode(filename)
    File.open(filename, 'rb') do |file|
      file.readlines
    end
  end
end
