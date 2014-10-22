require 'spec_helper'

describe BradyW::Nunit do
  before(:each) do
    ENV['nunit_filelist'] = nil
    FileUtils.rm 'something.txt' if File.exists?('something.txt')
    File.stub(:exists?) { |f|
      ['C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe', ''].include?(f)
    }
    Dir.stub(:exists?) { |d|
      [BswTech::DnetInstallUtil::PSTOOLS_PATH].include?(d)
    }
    @generated_output_file = 'generated_output_1.txt'
    @nunit_batch_file = 'run_nunit_elevated.bat'
    BradyW::TempFileNameGenerator.stub(:random_filename) { |base, extension|
      case extension
        when '.bat'
          @nunit_batch_file
        when '.txt'
          @generated_output_file
        else
          raise "Unknown extension #{extension}"
      end
    }
    FileUtils.stub(:rm) { |file|
      File.delete file if file != @nunit_batch_file
    }
    Rake.stub(:original_dir).and_return 'the/rakefile/path'
    ENV['PRESERVE_TEMP'] = nil
  end

  after(:each) do
    begin
      File.delete 'something.txt'
    rescue
    end
    begin
      File.delete @generated_output_file
    rescue
    end
    begin
      File.delete @nunit_batch_file
    rescue
    end
  end


  def mock_output_and_log_messages(options)
    options = {:file_name => @generated_output_file}.merge(options)
    # NUnit doesn't do funky encoding
    simulate_redirected_log_output(options[:task], :file_name => options[:file_name], :file_write_options => 'w') do |writer|
      writer << options[:messages]
    end
  end

  it 'throws error when NUnit could not be found' do
    File.stub(:exists?).with('C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe').and_return(false)
    File.stub(:exists?).with('C:/Program Files (x86)/NUnit-2.6.3/bin/nunit-console.exe').and_return(false)

    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
    end
    lambda { task.exectaskpublic }.should raise_exception("We checked the following locations and could not find nunit-console.exe [\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\", \"C:/Program Files (x86)/NUnit-2.6.3/bin/nunit-console.exe\"]")
  end

  it 'works when a ZIP file, not an MSI is installed, which has a different path' do
    File.stub(:exists?).with('C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe').and_return(false)
    File.stub(:exists?).with('C:/Program Files (x86)/NUnit-2.6.3/bin/nunit-console.exe').and_return(true)
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit-2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'shows correct default command line' do
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'doesnt test duplicate files' do
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file1.dll)
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll"
  end

  it 'uses NUnit 2.6.1' do
    File.stub(:exists?).with('C:/Program Files (x86)/NUnit 2.6.1/bin/nunit-console.exe').and_return(true)
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.version = '2.6.1'
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.1/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'uses a configured custom path' do
    File.stub(:exists?).with("C:\\SomeOtherplace/nunit-console.exe").and_return(true)
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.base_path = 'C:\\SomeOtherplace'
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:\\SomeOtherplace/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'uses a configured custom path with x86' do
    File.stub(:exists?).with("C:\\SomeOtherplace/nunit-console-x86.exe").and_return(true)
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.base_path = 'C:\\SomeOtherplace'
      test.arch = :x86
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:\\SomeOtherplace/nunit-console-x86.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'uses a configured custom path and the console is not found' do
    File.stub(:exists?).with("C:/SomeOtherplace/nunit-console.exe").and_return(false)
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.base_path = 'C:/SomeOtherplace'
    end

    lambda { task.exectaskpublic }.should raise_exception "We checked the following locations and could not find nunit-console.exe [\"C:/SomeOtherplace/nunit-console.exe\"]"
  end

  it 'uses a custom timeout' do
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.timeout = 25
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=25 file1.dll file2.dll"
  end

  it 'uses .NET 3.5' do
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.framework_version = :v3_5
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=3.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'can handle a single specific test to run' do
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.tests = 'some.test'
    end

    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 /run=some.test file1.dll file2.dll"
  end

  it 'can handle a multiple specific tests to run' do
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.tests = %w(some.test some.other.test)
    end

    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 /run=some.test,some.other.test file1.dll file2.dll"
  end

  it 'should work OK if XML output is turned on' do
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.xml_output = :enabled
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /framework=4.5 /timeout=35000 file1.dll file2.dll"

  end

  it 'Should work without labels' do
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.labels = :exclude_labels
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"

  end

  it 'Should work OK with custom errors and console output' do
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.output = 'somefile.txt'
      test.errors = 'someerrorfile.txt'
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /output=somefile.txt /err=someerrorfile.txt /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'Should work OK with x86 arch' do
    File.stub(:exists?).with("C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console-x86.exe").and_return(true)
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.arch = :x86
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console-x86.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'should allow the user to specify an assembly file list on the rake command line' do
    # arrange
    # just using this glob to make sure we are properly converting it to a FileList
    ENV['nunit_filelist'] = 'test/nun*_spec.rb'
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
    end

    # act
    task.exectaskpublic

    # assert
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 test/nunit_spec.rb"
  end

  it 'should work with normal security mode explicitly specified' do
    # arrange
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.security_mode = :normal
    end

    # act
    task.exectaskpublic

    # assert
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'should work with elevated security mode specified' do
    # arrange
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.security_mode = :elevated
    end
    mock_output_and_log_messages :task => task, :messages => 'stuff from nunit'
    console_text = []
    task.stub(:log) { |text| console_text << text }

    # act
    task.exectaskpublic

    # assert
    full_path = File.expand_path @nunit_batch_file
    windows_friendly = full_path.gsub(/\//, '\\')
    @commands.should include "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"#{windows_friendly}\""
    File.should be_exist(@nunit_batch_file) # because our test is checking the contents of the batch file
    lines = File.readlines @nunit_batch_file
    lines.length.should == 2
    lines[0].should == "cd the/rakefile/path\r\n"
    lines[1].should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /output=generated_output_1.txt /labels /framework=4.5 /timeout=35000 file1.dll file2.dll"
    expect(console_text).to include('stuff from nunit')
  end

  it 'should allow the output file to be overridden in elevated mode' do
    # arrange
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.security_mode = :elevated
      test.output = 'something.txt'
    end
    mock_output_and_log_messages :task => task, :messages => 'stuff from nunit', :file_name => 'something.txt'
    console_text = []
    task.stub(:log) { |text| console_text << text }

    # act
    task.exectaskpublic

    # assert
    full_path = File.expand_path @nunit_batch_file
    windows_friendly = full_path.gsub(/\//, '\\')
    @commands.should include "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"#{windows_friendly}\""
    File.should be_exist(@nunit_batch_file)
    lines = File.readlines @nunit_batch_file
    lines.length.should == 2
    lines[0].should == "cd the/rakefile/path\r\n"
    lines[1].should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /output=something.txt /labels /framework=4.5 /timeout=35000 file1.dll file2.dll"
    expect(console_text).to include('stuff from nunit')
    File.should_not be_exist('something.txt')
  end

  it 'should allow environment variables to be passed on to NUnit Console in elevated mode' do
    # arrange
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.security_mode = :elevated
      test.environment_variables = {:var1 => 'foo', :var2 => 'bar'}
    end
    mock_output_and_log_messages :task => task, :messages => 'stuff from nunit'

    # act
    task.exectaskpublic

    # assert
    File.should be_exist(@nunit_batch_file)
    lines = File.readlines @nunit_batch_file
    lines.length.should == 4
    lines[0].should == "set var1=foo\r\n"
    lines[1].should == "set var2=bar\r\n"
    lines[2].should == "cd the/rakefile/path\r\n"
    lines[3].should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /output=generated_output_1.txt /labels /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'should allow environment variables with spaces in the values to work properly with NUnit console in elevated mode' do
    # arrange
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.security_mode = :elevated
      test.environment_variables = {:var1 => 'foo', :var2 => 'bar with spaces'}
    end
    mock_output_and_log_messages :task => task, :messages => 'stuff from nunit'

    # act
    task.exectaskpublic

    # assert
    File.should be_exist(@nunit_batch_file)
    lines = File.readlines @nunit_batch_file
    lines.length.should == 4
    lines[0].should == "set var1=foo\r\n"
    # On Windows, we don't escape the spaces
    lines[1].should == "set var2=bar with spaces\r\n"
    lines[2].should == "cd the/rakefile/path\r\n"
    lines[3].should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /output=generated_output_1.txt /labels /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'should not freak out with environment variables of nil value' do
    # arrange
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.security_mode = :elevated
      test.environment_variables = {:var1 => 'foo', :var2 => nil}
    end
    mock_output_and_log_messages :task => task, :messages => 'stuff from nunit'

    # act
    task.exectaskpublic

    # assert
    File.should be_exist(@nunit_batch_file)
    lines = File.readlines @nunit_batch_file
    lines.length.should == 4
    lines[0].should == "set var1=foo\r\n"
    # On Windows, we don't escape the spaces
    lines[1].should == "set var2=\r\n"
    lines[2].should == "cd the/rakefile/path\r\n"
    lines[3].should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /output=generated_output_1.txt /labels /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'should cleanup the log files if the environment variable is not set' do
    # arrange
    FileUtils.unstub(:rm)
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.security_mode = :elevated
    end
    mock_output_and_log_messages :task => task, :messages => 'stuff from nunit'

    # act
    task.exectaskpublic

    # assert
    File.should_not be_exist(@generated_output_file)
    File.should_not be_exist(@nunit_batch_file)
  end

  it 'should preserve the log files if the environment variable is set' do
    # arrange
    FileUtils.unstub(:rm)
    ENV['PRESERVE_TEMP'] = 'true'
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.security_mode = :elevated
    end
    mock_output_and_log_messages :task => task, :messages => 'stuff from nunit'

    # act
    task.exectaskpublic

    # assert
    File.should be_exist(@generated_output_file)
    File.should be_exist(@nunit_batch_file)
  end

  it 'should run as a different user OK' do
    # arrange
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.run_as_user = 'theuser'
      test.run_as_password = 'thepassword'
    end
    mock_output_and_log_messages :task => task, :messages => 'stuff from nunit'
    console_text = []
    task.stub(:log) { |text| console_text << text }

    # act
    task.exectaskpublic

    # assert
    full_path = File.expand_path @nunit_batch_file
    windows_friendly = full_path.gsub(/\//, '\\')
    psexec_exe = File.join BswTech::DnetInstallUtil.ps_tools_base_path, 'PsExec.exe'
    @commands.should include "#{psexec_exe} -u theuser -p thepassword -i \"#{windows_friendly}\""
    File.should be_exist(@nunit_batch_file) # because our test is checking the contents of the batch file
    lines = File.readlines @nunit_batch_file
    lines.length.should == 2
    lines[0].should == "cd the/rakefile/path\r\n"
    lines[1].should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /output=generated_output_1.txt /labels /framework=4.5 /timeout=35000 file1.dll file2.dll"
    expect(console_text).to include('stuff from nunit')
  end

  it 'should allow environment variables to be passed when running as a different user' do
    # arrange
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.run_as_user = 'theuser'
      test.run_as_password = 'thepassword'
      test.environment_variables = {:var1 => 'foo', :var2 => 'bar with spaces'}
    end
    mock_output_and_log_messages :task => task, :messages => 'stuff from nunit'
    console_text = []
    task.stub(:log) { |text| console_text << text }

    # act
    task.exectaskpublic

    # assert
    File.should be_exist(@nunit_batch_file)
    lines = File.readlines @nunit_batch_file
    lines.length.should == 4
    lines[0].should == "set var1=foo\r\n"
    # On Windows, we don't escape the spaces
    lines[1].should == "set var2=bar with spaces\r\n"
    lines[2].should == "cd the/rakefile/path\r\n"
    lines[3].should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /output=generated_output_1.txt /labels /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end
end