require 'spec_helper'

describe BradyW::MSBuild do
  let(:execute_fails) { [] }
  let(:execute_succeeds) { [] }

  def run_command(command)
    if Bundler.clean_system command
      execute_succeeds << command
    else
      execute_fails << command
    end
  end

  def run_rake_targets(*targets)
    run_command "bundle exec rake #{[targets].join ' '}"
  end

  RSpec::Matchers.define :run_successfully do |matcher|
    match do
      if matcher
        matcher.matches? execute_fails
      else
        execute_fails.empty?
      end
    end

    failure_message do |matcher|
      if matcher
        matcher.failure_message
      else
        "Expected tasks to complete successfully but the following failed: #{execute_fails}"
      end
    end

    match_when_negated do
      if matcher
        matcher.does_not_match? execute_succeeds
      else
        execute_succeeds.any?
      end
    end

    failure_message_when_negated do |matcher|
      if matcher
        matcher.failure_message
      else
        "Expected tasks to NOT complete successfully but the following succeeded: #{execute_succeeds}"
      end
    end
  end

  RSpec::Matchers.define :have_dll_files do |matcher|
    def actual
      Dir.glob(File.join(project_dir, '**/*.dll'))
    end

    match do
      matcher.matches? actual
    end

    failure_message do
      matcher.failure_message + ", files in project dir: #{Dir.glob(File.join(project_dir, '**/*'))}"
    end
  end

  let(:project_dir) { File.join(File.dirname(__FILE__), 'RakeDotNet') }
  let(:project_gemfile) { File.join(project_dir, 'Gemfile') }

  class_variable_set :@@bundle_installed, []

  def self.bundle_install_complete_for(path)
    # initializer above does not set an array first
    class_variable_get(:@@bundle_installed) << path
  end

  def self.bundle_installed?(path)
    class_variable_get(:@@bundle_installed).include? path
  end

  before do
    # lock file is not versioned
    if self.class.bundle_installed?(project_gemfile)
      puts "\nSkipping bundle install for #{project_gemfile} because it has been done already\n"
    else
      FileUtils.rm_rf 'Gemfile.lock'
      run_command 'bundle install'
      self.class.bundle_install_complete_for project_gemfile
    end
  end

  around do |example|
    Dir.chdir project_dir do
      example.run
    end
  end

  subject do
    run_rake_targets *rake_targets
  end

  describe 'build' do
    before do
      Dir.glob(File.join(project_dir, '**/*.dll')).each { |f| File.delete f }
    end

    let(:rake_targets) { :build }

    it { is_expected.to run_successfully }
    it { is_expected.to have_dll_files include /RakeDotNet.dll/ }
  end

  describe 'clean' do
    let(:test_filename) { File.join(project_dir, 'artifacts/bin/RakeDotNet/Debug/dotnet/RakeDotNet.dll') }

    before do
      skip 'Even MSBuild is not cleaning right now'
      FileUtils.touch test_filename
    end

    after do
      FileUtils.rm_rf test_filename
    end

    let(:rake_targets) { :clean }

    it { is_expected.to run_successfully }
    it { is_expected.to_not have_dll_files include /RakeDotNet.dll/ }
  end
end
