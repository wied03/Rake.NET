require 'spec_helper'

describe BradyW::DotNetInstallerExecute do
  before :each do
    @should_deletes = []
    @file_index = 0
    allow(BradyW::TempFileNameGenerator).to receive(:random_filename) { |base, ext|
      file =
          case base
            when 'msi_log'
              'msi_log.txt'
            when 'dnet_log'
              'dnet_log.txt'
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

  def mock_output_and_log_messages(task, dnet_message, msi_message)
    if msi_message != nil
      # this task is unique in that in writes to 2 log files, so we borrow the block to do that as well
      dnet_log_written_already = false
      # Dnet installer always returns a failure code
      simulate_redirected_log_output(task, :file_name => 'msi_log.txt', :failure_return_code => true, :file_write_options => 'w:UTF-16LE:UTF-8') do |writer|
        unless dnet_log_written_already
          File.open 'dnet_log.txt', 'w' do |writer|
            writer << dnet_message
          end
          dnet_log_written_already = true
        end

        writer << msi_message
      end
    else
      # sometimes MSI messages may be null
      File.open 'dnet_log.txt', 'w' do |writer|
        writer << dnet_message
      end
    end
  end

  it 'should work properly in install mode with no properties' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'stuff/some.exe'
      t.mode = :install
    end
    mock_output_and_log_messages task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 0 (0x0)', 'MSI log messages'

    # act
    task.exectaskpublic

    # assert
    expect(@commands.first).to eq("#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"stuff\\some.exe\" /i /ComponentArgs *:\"/l* msi_log.txt\" /q /Log /LogFile dnet_log.txt")
  end

  it 'should output MSI and dnet installer log messages to the console' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'stuff/some.exe'
      t.mode = :install
    end
    mock_output_and_log_messages task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 0 (0x0)', 'MSI log messages'
    console_text = []
    allow(task).to receive(:log) { |text| console_text << text }

    # act
    task.exectaskpublic

    # assert
    expect(console_text).to eq(['.NET Installer Log', "2014-01-15 00:34:27\tdotNetInstaller finished, return code: 0 (0x0)", "\nMSI Log:", 'MSI log messages'])
  end

  it 'should work properly in install mode with a single property' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
      t.properties = {:SOMETHING => 'stuff'}
    end
    mock_output_and_log_messages task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 0 (0x0)', 'MSI log messages'

    # act
    task.exectaskpublic

    # assert
    expect(@commands.first).to eq("#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"some.exe\" /i /ComponentArgs *:\"/l* msi_log.txt SOMETHING=stuff\" /q /Log /LogFile dnet_log.txt")
  end

  it 'should not freak out if a nil value is passed for a property' do
    # arrange
    ENV['foobar'] = nil
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
      t.properties = {:SOMETHING => nil}
    end
    mock_output_and_log_messages task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 0 (0x0)', 'MSI log messages'

    # act
    task.exectaskpublic

    # assert
    expect(@commands.first).to eq(BswTech::DnetInstallUtil::ELEVATE_EXE+' -w "some.exe" /i /ComponentArgs *:"/l* msi_log.txt SOMETHING=""""" /q /Log /LogFile dnet_log.txt')
  end

  it 'should work properly in install mode with multiple properties with whitespace and quotes' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
      t.properties = {:SOMETHING => 'stuff', :SPACES => 'hi there', :QUOTES => 'hello "there" joe'}
    end
    mock_output_and_log_messages task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 0 (0x0)', 'MSI log messages'

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    expect(@commands.first).to eq(BswTech::DnetInstallUtil::ELEVATE_EXE+' -w "some.exe" /i /ComponentArgs *:"/l* msi_log.txt SOMETHING=stuff SPACES=""hi there"" QUOTES=""hello """"there"""" joe""" /q /Log /LogFile dnet_log.txt')
  end

  it 'should work properly with uninstall' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :uninstall
    end
    mock_output_and_log_messages task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 0 (0x0)', 'MSI log messages'

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    expect(@commands.first).to eq("#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"some.exe\" /x /ComponentArgs *:\"/l* msi_log.txt\" /q /Log /LogFile dnet_log.txt")
  end

  it 'should require mode and path' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'mode and path are required'
  end

  it 'should complain about an invalid mode' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :foobar
    end

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'mode cannot be :foobar, must be either :install or :uninstall'
  end

  it 'should fail if the log message does not indicate success' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
    end
    mock_output_and_log_messages task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 1 (0x1)', 'MSI log messages'

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'Due to lack of success message in logs, this task has failed'
  end

  it 'should clean up temporary log files upon success' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
    end
    mock_output_and_log_messages task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 0 (0x0)', 'MSI log messages'

    # act
    task.exectaskpublic

    # assert
    File.should_not be_exist(@should_deletes[0])
    File.should_not be_exist(@should_deletes[1])
  end

  it 'should clean up temporary log files upon failure' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
    end
    mock_output_and_log_messages task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 1 (0x1)', 'MSI log messages'

    # act
    lambda { task.exectaskpublic }.should raise_exception

    # assert
    File.should_not be_exist(@should_deletes[0])
    File.should_not be_exist(@should_deletes[1])
  end

  it 'should clean up temp logs when dnet installer fails and an MSI log file is never generated' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
    end
    mock_output_and_log_messages task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 1 (0x1)', nil

    # act
    lambda { task.exectaskpublic }.should raise_exception

    # assert
    File.should_not be_exist(@should_deletes[0])
    File.should_not be_exist(@should_deletes[1])
  end

  it 'should clean up temp logs when dnet installer succeeds and an MSI log file is never generated' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
    end
    mock_output_and_log_messages task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 0 (0x0)', nil

    # act
    task.exectaskpublic

    # assert
    File.should_not be_exist(@should_deletes[0])
    File.should_not be_exist(@should_deletes[1])
  end
end
