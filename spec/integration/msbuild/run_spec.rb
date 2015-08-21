require 'spec_helper'

describe BradyW::MSBuild do
  RSpec::Matchers.define :run_successfully do
    match do
      @success
    end

    failure_message do
      'Expected task to succeed but it did not'
    end
  end

  describe 'build' do
    before do
      Dir.chdir(File.join(File.dirname(__FILE__), 'RakeDotNet')) do
        Bundler.clean_system 'bundle exec rake build'
        @success = $?.success?
      end
    end

    it { is_expected.to run_successfully }
    pending 'finish'
  end

  describe 'clean' do
    pending 'write this'
  end
end
