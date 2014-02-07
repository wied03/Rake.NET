require 'base'
require 'subinacl'

describe BradyW::Subinacl do

  before(:each) do
    @should_deletes = []
    @file_index = 0
    BradyW::TempFileNameGenerator.stub(:random_filename) { |base, ext|
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
    FileUtils.stub(:rm) { |file|
      File.delete file if file != 'run_subinacl_with_output_redirect.bat'
    }
    @commands = []
    ENV['PRESERVE_TEMP'] = nil
    File.stub(:expand_path) {|f| "/some/base/dir/#{f}" }
  end

  after :each do
    @should_deletes.each { |f| File.delete f if (f && File.exists?(f)) }
    File.unstub(:expand_path)
  end


  def generate_subinacl_output(opts)
    "Done:        0, Modified        0, Failed        #{opts[:failure_count_to_indicate]}, Syntax errors        #{opts[:syntax_error_count_to_indicate]}"
  end

  def mock_output_and_log_messages(options)
    task = options.is_a?(Hash) ? options[:task] : options
    opts = {:syntax_error_count_to_indicate => 0, :failure_count_to_indicate => 0}
    opts.merge! options if options.is_a?(Hash)
    task.stub(:shell) { |*commands|
      # Simulate dotNetInstaller logging to the file
      File.open 'subinacl_log.txt', 'w' do |writer|
        writer << generate_subinacl_output(opts)
      end
      puts commands
      @commands = commands
    }
  end

  it 'should run Subinacl properly when no spaces are in path' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    task.stub(:subinacl_path).and_return('\path\to\subinacl.exe')
    mock_output_and_log_messages task

    # act
    task.exectaskpublic

    # assert
    full_path = File.expand_path 'run_subinacl_with_output_redirect.bat'
    windows_friendly = full_path.gsub(/\//, '\\')
    @commands.should include "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"#{windows_friendly}\""
    File.should be_exist('run_subinacl_with_output_redirect.bat')
    lines = File.readlines 'run_subinacl_with_output_redirect.bat'
    lines.should have(1).items
    lines[0].should == '"\path\to\subinacl.exe" /service theservice /grant=theuser=top 1> "\some\base\dir\subinacl_log.txt" 2>&1'
  end

  it 'should run Subinacl properly when spaces are in path' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    task.stub(:subinacl_path).and_return('\path\to the\subinacl.exe')
    mock_output_and_log_messages task

    # act
    task.exectaskpublic

    # assert
    full_path = File.expand_path 'run_subinacl_with_output_redirect.bat'
    windows_friendly = full_path.gsub(/\//, '\\')
    @commands.should include "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"#{windows_friendly}\""
    File.should be_exist('run_subinacl_with_output_redirect.bat')
    lines = File.readlines 'run_subinacl_with_output_redirect.bat'
    lines.should have(1).items
    lines[0].should == '"\path\to the\subinacl.exe" /service theservice /grant=theuser=top 1> "\some\base\dir\subinacl_log.txt" 2>&1'
  end

  it 'should output log information to the console' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    task.stub(:subinacl_path).and_return('\path\to the\subinacl.exe')
    mock_output_and_log_messages task
    console_text = []
    task.stub(:log) { |text| console_text << text }

    # act
    task.exectaskpublic

    # assert
    console_text.should include('Done:        0, Modified        0, Failed        0, Syntax errors        0')
  end

  it 'should fail if Subinacl outputs a failure count since subinacl doesnt use return codes properly' do
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    task.stub(:subinacl_path).and_return('\path\to\subinacl.exe')
    mock_output_and_log_messages :task => task, :failure_count_to_indicate => 1

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'Subinacl failed due to syntax errors or failures in making the requested change'
  end

  it 'should fail if Subinacl outputs a syntax error since subinacl doesnt use return codes properly' do
      task = BradyW::Subinacl.new do |t|
        t.service_to_grant_access_to = 'theservice'
        t.user_to_grant_top_access_to = 'theuser'
      end
      task.stub(:subinacl_path).and_return('\path\to\subinacl.exe')
      mock_output_and_log_messages :task => task, :syntax_error_count_to_indicate => 1

      # act + assert
      lambda { task.exectaskpublic }.should raise_exception 'Subinacl failed due to syntax errors or failures in making the requested change'
    end

  it 'should complain if subnacl is not installed' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    task.stub(:subinacl_path).and_return(nil)

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'Subinacl not found on your system.  Did you install MSI version 5.2.3790 ?'
  end

  it 'should delete temporary log file when successful' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    task.stub(:subinacl_path).and_return('\path\to the\subinacl.exe')
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
    task.stub(:subinacl_path).and_return('\path\to the\subinacl.exe')
    mock_output_and_log_messages :task => task, :syntax_error_count_to_indicate => 1

    # act
    lambda {task.exectaskpublic}.should raise_exception

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
    task.stub(:subinacl_path).and_return('\path\to the\subinacl.exe')
    mock_output_and_log_messages task

    # act
    task.exectaskpublic

    # assert
    File.should be_exist('subinacl_log.txt')
    File.should be_exist('run_subinacl_with_output_redirect.bat')
  end
end