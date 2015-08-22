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

  RSpec::Matchers.alias_matcher :execute_bins, :execute_bin

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

  before do
    BradyW::BaseTask.clear_shell_stack
  end
end
