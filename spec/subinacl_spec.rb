require 'base'
require 'subinacl'

describe BradyW::Subinacl do

  before(:each) do
    @should_deletes = []
    @file_index = 0
    BradyW::TempFileNameGenerator.stub(:random_filename) { |base, ext|
      file =
          case base
            when 'run_subinacl_without_output_redirect'
              'run_subinacl_without_output_redirect.bat'
            else
              raise "Unknown extension #{extension}"
          end
      @should_deletes << file
      file
    }
    @commands = []
    ENV['PRESERVE_TEMP'] = nil
  end

  after :each do
    @should_deletes.each { |f| rm f if (f && File.exists?(f)) }
  end


  def generate_subinacl_output(error_count)
    "Done:        0, Modified        0, Failed        0, Syntax errors        #{error_count}"
  end

  def mock_output_and_log_messages(task, options)
    task.stub(:shell) { |*commands, &block|
      # Simulate dotNetInstaller logging to the file
      File.open 'run_subinacl_without_output_redirect.bat', 'w' do |writer|
        writer << generate_subinacl_output(options[:error_count_to_indicate])
      end
      puts commands
      @commands = commands
      block.call
    }
  end

  it 'should run Subinacl properly when no spaces are in path' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    task.should_receive(:subinacl_path).and_return('\path\to\subinacl.exe')
    mock_output_and_log_messages task, :error_count_to_indicate => 0

    # act
    task.exectaskpublic

    # assert
    @commands.should include "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"\\path\\to\\subinacl.exe\" /service theservice /grant=theuser=top"
  end

  it 'should run Subinacl properly when spaces are in path' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    task.should_receive(:subinacl_path).and_return('\path\to the\subinacl.exe')
    mock_output_and_log_messages task, :error_count_to_indicate => 0

    # act
    task.exectaskpublic

    # assert
    @commands.should include "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"\\path\\to the\\subinacl.exe\" /service theservice /grant=theuser=top"
  end

  it 'should output log information to the console' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    task.should_receive(:subinacl_path).and_return('\path\to the\subinacl.exe')
    mock_output_and_log_messages task, :error_count_to_indicate => 0
    console_text = []
    task.stub(:log) { |text| console_text << text }

    # act
    task.exectaskpublic

    # assert
    console_text.should == 'subinacl output'
  end

  it 'should fail if Subinacl outputs an error count since subinacl doesnt use return codes properly' do
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    task.should_receive(:subinacl_path).and_return('\path\to\subinacl.exe')
    mock_output_and_log_messages task, :error_count_to_indicate => 1

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'Subinacl failed'
  end

  it 'should complain if subnacl is not installed' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    task.should_receive(:subinacl_path).and_return(nil)

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'Subinacl not found on your system.  Did you install MSI version XXX?'
  end

  it 'should delete temporary log file when successful' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    task.should_receive(:subinacl_path).and_return('\path\to the\subinacl.exe')
    mock_output_and_log_messages task, :error_count_to_indicate => 0

    # act
    task.exectaskpublic

    # assert
    File.should_not be_exist('run_subinacl_without_output_redirect.bat')
  end

  it 'should delete temporary log file when failed' do
    # arrange
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    task.should_receive(:subinacl_path).and_return('\path\to the\subinacl.exe')
    mock_output_and_log_messages task, :error_count_to_indicate => 1

    # act
    task.exectaskpublic

    # assert
    File.should_not be_exist('run_subinacl_without_output_redirect.bat')
  end

  it 'should preserve temp files if environment variable is set' do
    # arrange
    ENV['PRESERVE_TEMP'] = 'true'
    task = BradyW::Subinacl.new do |t|
      t.service_to_grant_access_to = 'theservice'
      t.user_to_grant_top_access_to = 'theuser'
    end
    task.should_receive(:subinacl_path).and_return('\path\to the\subinacl.exe')
    mock_output_and_log_messages task, :error_count_to_indicate => 0

    # act
    task.exectaskpublic

    # assert
    File.should be_exist('run_subinacl_without_output_redirect.bat')
  end
end