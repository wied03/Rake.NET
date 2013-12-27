require 'base'
require 'dot_net_installer_execute'

describe BradyW::DotNetInstallerExecute do
  it 'should work properly in install mode with no properties' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
    end

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    expect(command).to eq('some.exe /i /q')
  end

  it 'should work properly in install mode with a single property' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
      t.properties = {:SOMETHING => 'stuff'}
    end

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    expect(command).to eq('some.exe /i /ComponentArgs *:"SOMETHING=stuff" /q')
  end

  it 'should work properly in install mode with multiple properties with whitespace and quotes' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :install
      t.properties = {:SOMETHING => 'stuff', :SPACES => 'hi there', :QUOTES => 'hello "there" joe'}
    end

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    expect(command).to eq('some.exe /i /ComponentArgs *:"SOMETHING=stuff SPACES=""hi there"" QUOTES=""hello """"there"""" joe""" /q')
  end

  it 'should work properly with uninstall' do
    # arrange
    task = BradyW::DotNetInstallerExecute.new do |t|
      t.path = 'some.exe'
      t.mode = :uninstall
    end

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    expect(command).to eq('some.exe /x /q')
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
end