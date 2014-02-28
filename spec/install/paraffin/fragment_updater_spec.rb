require 'spec_helper'

class ParaffinReportDifferentError
  def exitstatus
    4
  end
end

module BradyW
  module Paraffin
    class FragmentUpdater
         def cmd_exe
           'C:\WinDir\cmd.exe'
         end
    end
  end
end

describe BradyW::Paraffin::FragmentUpdater do
  before(:each) do
    begin
      File.unstub(:exists?)
    rescue RSpec::Mocks::MockExpectationError
    end
    @mockBasePath = 'someParaffinPath\Paraffin.exe'
    stub_const 'BswTech::DnetInstallUtil::PARAFFIN_EXE', @mockBasePath
    File.stub(:absolute_path) do |p|
      if p[0] == '/'
        p
      else
        File.join '/root/dir/for', p
      end
    end
  end

  it 'must supply the WXS value' do
    # arrange
    task = BradyW::Paraffin::FragmentUpdater.new

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception ':fragment_file and :output_directory are required for this task'
  end

  it 'should work OK when the WXS value is supplied' do
    # arrange
    task = BradyW::Paraffin::FragmentUpdater.new do |t|
      t.fragment_file = 'some_file.wxs'
      t.output_directory = '..\Bin\Release'
    end
    original_file = nil
    destination_file = nil
    FileUtils.stub(:mv) do |orig, dest|
      original_file = orig
      destination_file = dest
    end
    File.stub(:exist?).and_return(true)

    # act
    task.exectaskpublic
    command3 = task.executedPop
    command2 = task.executedPop
    command1 = task.executedPop

    # assert
    command1.should == 'C:\WinDir\cmd.exe /c mklink /J "\root\dir\for\.\paraffin_config_aware_symlink" "\root\dir\for\..\Bin\Release"'
    command2.should == '"someParaffinPath\Paraffin.exe" -update "some_file.wxs" -verbose -ReportIfDifferent'
    command3.should == 'rmdir "\root\dir\for\.\paraffin_config_aware_symlink"'
    original_file.should == './some_file.PARAFFIN'
    destination_file.should == 'some_file.wxs'
  end

  it 'should work properly with the ReportIfDifferent error codes from Paraffin' do
    # arrange
    task = BradyW::Paraffin::FragmentUpdater.new do |t|
      t.fragment_file = 'some_file.wxs'
      t.output_directory = '..\Bin\Release'
    end
    @commands = []
    task.stub(:shell) { |*commands, &block|
      puts commands
      @commands += commands
      block[nil, ParaffinReportDifferentError.new] if commands[0].include?('Paraffin.exe')
    }
    original_file = nil
    destination_file = nil
    FileUtils.stub(:mv) do |orig, dest|
      original_file = orig
      destination_file = dest
    end
    File.stub(:exist?).and_return(true)

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'some_file.wxs has changed.  Review updates to some_file.wxs manually and rebuild'
    original_file.should == './some_file.PARAFFIN'
    destination_file.should == 'some_file.wxs'
  end

  it 'should work properly with different directories' do
    # arrange
    task = BradyW::Paraffin::FragmentUpdater.new do |t|
      t.fragment_file = 'someDirectory/some_file.wxs'
      t.output_directory = '../Bin/Release'
    end
    original_file = nil
    destination_file = nil
    FileUtils.stub(:mv) do |orig, dest|
      original_file = orig
      destination_file = dest
    end
    File.stub(:exist?).and_return(true)

    # act
    task.exectaskpublic
    command3 = task.executedPop
    command2 = task.executedPop
    command1 = task.executedPop

    # assert
    command1.should == 'C:\WinDir\cmd.exe /c mklink /J "\root\dir\for\someDirectory\paraffin_config_aware_symlink" "\root\dir\for\..\Bin\Release"'
    command2.should == '"someParaffinPath\Paraffin.exe" -update "someDirectory/some_file.wxs" -verbose -ReportIfDifferent'
    command3.should == 'rmdir "\root\dir\for\someDirectory\paraffin_config_aware_symlink"'
    original_file.should == 'someDirectory/some_file.PARAFFIN'
    destination_file.should == 'someDirectory/some_file.wxs'
  end

  it 'should handle an error in Paraffin OK when replacing the generated file (and Paraffin did NOT generate the file)' do
    # arrange
    task = BradyW::Paraffin::FragmentUpdater.new do |t|
      t.fragment_file = 'someDirectory/some_file.wxs'
      t.output_directory = '..\Bin\Release'
    end
    @commands = []
    task.stub(:shell) { |*commands, &block|
      puts commands
      @commands += commands
      block[nil, SimulateProcessFailure.new] if commands[0].include?('Paraffin.exe')
    }
    File.stub(:exists?).and_return(false)
    FileUtils.stub(:mv) do |orig, dest|
      raise 'No such file or directory test!'
    end

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception "Paraffin failed with status code: 'BW Rake Task Problem'"
  end

  it 'should clean up the symlink even when Paraffin fails' do
    # arrange
    task = BradyW::Paraffin::FragmentUpdater.new do |t|
      t.fragment_file = 'some_file.wxs'
      t.output_directory = '..\Bin\Release'
    end
    @commands = []
    task.stub(:shell) { |*commands, &block|
      puts commands
      @commands += commands
      block[nil, SimulateProcessFailure.new] if commands[0].include?('Paraffin.exe')
    }

    # act
    lambda { task.exectaskpublic }.should raise_exception "Paraffin failed with status code: 'BW Rake Task Problem'"

    # assert
    @commands[0].should == 'C:\WinDir\cmd.exe /c mklink /J "\root\dir\for\.\paraffin_config_aware_symlink" "\root\dir\for\..\Bin\Release"'
    @commands[1].should == '"someParaffinPath\Paraffin.exe" -update "some_file.wxs" -verbose -ReportIfDifferent'
    @commands[2].should == 'rmdir "\root\dir\for\.\paraffin_config_aware_symlink"'
  end
end