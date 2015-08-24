require 'spec_helper'

describe BradyW::Subinacl do
  include_context :executable_test
  include_context :io_helper

  before(:each) do
    @should_deletes = []
    @file_index = 0
    allow(BradyW::TempFileNameGenerator).to receive(:random_filename) { |base, ext|
                                              file =
                                                  case base
                                                    when 'run_subinacl_with_output_redirect'
                                                      "#{base}#{ext}"
                                                    when 'subinacl_log'
                                                      "#{base}#{ext}"
                                                    else
                                                      raise "Unknown extension #{extension}"
                                                  end
                                              @should_deletes << file
                                              file
                                            }
    # Need to examine the batch file as part of our tests
    allow(FileUtils).to receive(:rm) { |file|
                          File.delete file if file != 'run_subinacl_with_output_redirect.bat'
                        }
    @commands = []
    ENV['PRESERVE_TEMP'] = nil
    allow(File).to receive(:expand_path) { |f| "/some/base/dir/#{f}" }
  end

  after :each do
    @should_deletes.each { |f| File.delete f if (f && File.exists?(f)) }
  end

  def generate_subinacl_output(opts)
    "Done:        0, Modified        0, Failed        #{opts[:failure_count_to_indicate]}, Syntax errors        #{opts[:syntax_error_count_to_indicate]}"
  end

  def mock_output_and_log_messages(options)
    options = {:syntax_error_count_to_indicate => 0, :failure_count_to_indicate => 0, :object_failure => nil}.merge((options.is_a?(Hash) ? options : {:task => options}))
    simulate_redirected_log_output(options[:task], :file_name => 'subinacl_log.txt') do |writer|
      writer << generate_subinacl_output(options)
      # Tests on Win8 show MAC line endings (CR, not CRLF or LF) and this encoding, so mimic that
      writer << "\r"
      writer << "Current object #{options[:object_failure]} will not be processed\r" if options[:object_failure]
    end
  end

  subject(:task) { BradyW::Subinacl.new }

  describe '#subinacl_path' do
    before do
      mock_msi_searcher = instance_double BradyW::MsiFileSearcher
      allow(BradyW::MsiFileSearcher).to receive(:new).and_return(mock_msi_searcher)
      allow(mock_msi_searcher).to receive(:get_component_path).with('{D3EE034D-5B92-4A55-AA02-2E6D0A6A96EE}', '{C2BC2826-FDDC-4A61-AA17-B3928B0EDA38}').and_return('path\to\subinacl.exe')
    end

    subject { task.send(:subinacl_path) }

    it { is_expected.to eq 'path\to\subinacl.exe' }
  end

  it 'should run Subinacl properly when no spaces are in path' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    allow(task).to receive(:subinacl_path).and_return('\path\to\subinacl.exe')
    mock_output_and_log_messages task

    # act
    task.exectaskpublic

    # assert
    full_path = File.expand_path 'run_subinacl_with_output_redirect.bat'
    windows_friendly = full_path.gsub(/\//, '\\')
    @commands.should include "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"#{windows_friendly}\""
    File.should be_exist('run_subinacl_with_output_redirect.bat')
    lines = File.readlines 'run_subinacl_with_output_redirect.bat'
    lines.length.should == 1
    lines[0].should == '"\path\to\subinacl.exe" /service theservice /grant=theuser=top 1> "\some\base\dir\subinacl_log.txt" 2>&1'
  end

  it 'should run Subinacl properly when spaces are in path' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    allow(task).to receive(:subinacl_path).and_return('\path\to the\subinacl.exe')
    mock_output_and_log_messages task

    # act
    task.exectaskpublic

    # assert
    full_path = File.expand_path 'run_subinacl_with_output_redirect.bat'
    windows_friendly = full_path.gsub(/\//, '\\')
    @commands.should include "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"#{windows_friendly}\""
    File.should be_exist('run_subinacl_with_output_redirect.bat')
    lines = File.readlines 'run_subinacl_with_output_redirect.bat'
    lines.length.should == 1
    lines[0].should == '"\path\to the\subinacl.exe" /service theservice /grant=theuser=top 1> "\some\base\dir\subinacl_log.txt" 2>&1'
  end

  it 'should output log information to the console' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    allow(task).to receive(:subinacl_path).and_return('\path\to the\subinacl.exe')
    mock_output_and_log_messages task
    console_text = StringIO.new
    allow(task).to receive(:log) { |text| console_text.puts text }

    # act
    task.exectaskpublic

    # assert
    console_text.string.should include("Done:        0, Modified        0, Failed        0, Syntax errors        0\n")
  end

  it 'should fail if Subinacl outputs a failure count since subinacl doesnt use return codes properly' do
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    allow(task).to receive(:subinacl_path).and_return('\path\to\subinacl.exe')
    mock_output_and_log_messages :task => task, :failure_count_to_indicate => 1

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'Subinacl failed due to syntax errors or failures in making the requested change'
  end

  it 'should fail if Subinacl outputs a syntax error since subinacl doesnt use return codes properly' do
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    allow(task).to receive(:subinacl_path).and_return('\path\to\subinacl.exe')
    mock_output_and_log_messages :task => task, :syntax_error_count_to_indicate => 1

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'Subinacl failed due to syntax errors or failures in making the requested change'
  end

  it 'should fail if Subinacl fails for another unknown reason' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    allow(task).to receive(:subinacl_path).and_return('\path\to\subinacl.exe')
    mock_output_and_log_messages :task => task, :object_failure => 'theservice'

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'Subinacl failed due to syntax errors or failures in making the requested change'
  end

  it 'should complain if Subinacl is not installed' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    allow(task).to receive(:subinacl_path).and_return(nil)

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'Subinacl not found on your system.  Did you install MSI version 5.2.3790 ?'
  end

  it 'should delete temporary log file when successful' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    allow(task).to receive(:subinacl_path).and_return('\path\to the\subinacl.exe')
    mock_output_and_log_messages task

    # act
    task.exectaskpublic

    # assert
    File.should_not be_exist('subinacl_log.txt')
    File.should_not be_exist('run_subinacl_without_output_redirect.bat')
  end

  it 'should delete temporary log file when failed' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    allow(task).to receive(:subinacl_path).and_return('\path\to the\subinacl.exe')
    mock_output_and_log_messages :task => task, :syntax_error_count_to_indicate => 1

    # act
    lambda { task.exectaskpublic }.should raise_exception

    # assert
    File.should_not be_exist('subinacl_log.txt')
    File.should_not be_exist('run_subinacl_without_output_redirect.bat')
  end

  it 'should preserve temp files if environment variable is set' do
    # arrange
    ENV['PRESERVE_TEMP'] = 'true'
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    allow(task).to receive(:subinacl_path).and_return('\path\to the\subinacl.exe')
    mock_output_and_log_messages task

    # act
    task.exectaskpublic

    # assert
    File.should be_exist('subinacl_log.txt')
    File.should be_exist('run_subinacl_with_output_redirect.bat')
  end
end
