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

  before do
    Dir.chdir(project_dir) do
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
