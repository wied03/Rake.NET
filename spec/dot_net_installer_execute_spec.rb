require 'base'
require 'dot_net_installer_execute'

describe BradyW::DotNetInstallerExecute do
  before :each do
    @should_deletes = []
    @file_index = 0
    BradyW::TempFileNameGenerator.stub(:filename) {
      @file_index += 1
      file = "generated_name_#{@file_index}.xml"
      @should_deletes << file
      file
    }
    @commands = []
    ENV['PRESERVE_TEMP'] = nil
  end

  after :each do
    @should_deletes.each { |f| rm f if (f && File.exists?(f)) }
  end

  def mock_output_and_log_message(task, message)
    task.stub(:shell) { |*commands, &block|
      # Simulate dotNetInstaller logging to the file
      File.open @should_deletes.last, 'w' do |writer|
        writer << message
      end
      puts commands
      @commands = commands
      block.call(nil, SimulateProcessFailure.new)
    }
  end

  it 'should work properly in install mode with no properties' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'stuff/some.exe'
      t.mode = :install
    end
    mock_output_and_log_message task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 0 (0x0)'

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    expect(@commands.first).to eq('/Users/brady/.rvm/gems/ruby-1.9.3-p484@rakenet/gems/bsw_dnet_install_util-1.1.3/lib/elevate-1.3.0/elevate.exe -w "stuff\\some.exe" /i /q /Log /LogFile generated_name_1.xml')
  end

  it 'should work properly in install mode with a single property' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
      t.properties = {:SOMETHING => 'stuff'}
    end
    mock_output_and_log_message task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 0 (0x0)'

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    expect(@commands.first).to eq('/Users/brady/.rvm/gems/ruby-1.9.3-p484@rakenet/gems/bsw_dnet_install_util-1.1.3/lib/elevate-1.3.0/elevate.exe -w "some.exe" /i /ComponentArgs *:"SOMETHING=stuff" /q /Log /LogFile generated_name_1.xml')
  end

  it 'should work properly in install mode with multiple properties with whitespace and quotes' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
      t.properties = {:SOMETHING => 'stuff', :SPACES => 'hi there', :QUOTES => 'hello "there" joe'}
    end
    mock_output_and_log_message task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 0 (0x0)'

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    expect(@commands.first).to eq('/Users/brady/.rvm/gems/ruby-1.9.3-p484@rakenet/gems/bsw_dnet_install_util-1.1.3/lib/elevate-1.3.0/elevate.exe -w "some.exe" /i /ComponentArgs *:"SOMETHING=stuff SPACES=""hi there"" QUOTES=""hello """"there"""" joe""" /q /Log /LogFile generated_name_1.xml')
  end

  it 'should work properly with uninstall' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :uninstall
    end
    mock_output_and_log_message task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 0 (0x0)'

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    expect(@commands.first).to eq('/Users/brady/.rvm/gems/ruby-1.9.3-p484@rakenet/gems/bsw_dnet_install_util-1.1.3/lib/elevate-1.3.0/elevate.exe -w "some.exe" /x /q /Log /LogFile generated_name_1.xml')
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
    mock_output_and_log_message task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 1 (0x1)'

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'Due to failure message in logs, this task has failed'
  end

  it 'should clean up temporary log files upon success' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
    end
    mock_output_and_log_message task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 0 (0x0)'

    # act
    task.exectaskpublic

    # assert
    File.should_not be_exist(@should_deletes[0])
  end

  it 'should clean up temporary log files upon failure' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
    end
    mock_output_and_log_message task, '2014-01-15 00:34:27	dotNetInstaller finished, return code: 1 (0x1)'

    # act
    lambda { task.exectaskpublic }.should raise_exception 'Due to failure message in logs, this task has failed'

    # assert
    File.should_not be_exist(@should_deletes[0])
  end
end