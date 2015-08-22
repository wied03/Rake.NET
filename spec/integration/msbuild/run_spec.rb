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

  RSpec::Matchers.define :have_dll_files do |matcher|
    def actual
      Dir.glob(File.join(project_dir, '**/*.dll'))
    end

    match do
      matcher.matches? actual
    end

    failure_message do
      matcher.failure_message
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
    Dir.chdir(project_dir) do
      # lock file is not versioned
      if self.class.bundle_installed?(project_gemfile)
        puts "\nSkipping bundle install for #{project_gemfile} because it has been done already\n"
      else
        FileUtils.rm_rf 'Gemfile.lock'
        Bundler.clean_system 'bundle install'
        @success = $?.success?
        raise 'Bundle install error' unless @success
        self.class.bundle_install_complete_for project_gemfile
      end
      Bundler.clean_system "bundle exec rake #{[*rake_targets].join ' '}"
      @success = $?.success?
    end
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
    let(:test_filename) { File.join(project_dir, 'RakeDotNet.dll') }

    before do
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
