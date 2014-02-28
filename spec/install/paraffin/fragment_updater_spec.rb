require 'spec_helper'

class ParaffinReportDifferentError
  def exitstatus
    4
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
  end

  it 'must supply the WXS value' do
    # arrange
    task = BradyW::Paraffin::FragmentUpdater.new

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception ':fragment_file and :output_directory are required for this task'
  end

  it 'should work OK when the WXS value is supplied and replace original is off' do
    # arrange
    task = BradyW::Paraffin::FragmentUpdater.new do |t|
      t.fragment_file = 'some_file.wxs'
      t.replace_original = false
      t.output_directory = '..\Bin\Release'
    end
    FileUtils.stub(:rm).and_throw 'Should not be removing any files'

    # act
    task.exectaskpublic
    command3 = task.executedPop
    command2 = task.executedPop
    command1 = task.executedPop

    # assert
    command1.should == 'cmd.exe /c mklink /J ".\paraffin_config_aware_symlink" "..\Bin\Release"'
    command2.should == '"someParaffinPath\Paraffin.exe" -update "some_file.wxs" -verbose -ReportIfDifferent'
    command3.should == 'rmdir ".\paraffin_config_aware_symlink"'
  end

  it 'should work properly with the ReportIfDifferent error codes from Paraffin' do
    # arrange
    task = BradyW::Paraffin::FragmentUpdater.new do |t|
      t.fragment_file = 'some_file.wxs'
      t.replace_original = false
      t.output_directory = '..\Bin\Release'
    end
    @commands = []
    task.stub(:shell) { |*commands, &block|
      puts commands
      @commands += commands
      block[nil, ParaffinReportDifferentError.new] if commands[0].include?('Paraffin.exe')
    }

    FileUtils.stub(:rm).and_throw 'Should not be removing any files'

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'some_file.wxs has changed and you don\'t have :replace_original enabled.  Manually update some_file.wxs using ./some_file.PARAFFIN or enable :replace_original'
  end

  it 'should replace the output file with Paraffin' 's generated file if told to do so' do
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

    # act
    task.exectaskpublic
    command3 = task.executedPop
    command2 = task.executedPop
    command1 = task.executedPop

    # assert
    command1.should == 'cmd.exe /c mklink /J "someDirectory\paraffin_config_aware_symlink" "..\Bin\Release"'
    command2.should == '"someParaffinPath\Paraffin.exe" -update "someDirectory/some_file.wxs" -verbose'
    command3.should == 'rmdir "someDirectory\paraffin_config_aware_symlink"'
    original_file.should == 'someDirectory/some_file.PARAFFIN'
    destination_file.should == 'someDirectory/some_file.wxs'
  end

  it 'should handle an error in Paraffin OK when replacing the generated file (if Paraffin generated the file)' do
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
    deleted_file = nil
    FileUtils.stub(:rm) do |f|
      deleted_file = f
    end
    File.stub(:exists?).and_return(true)

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception "Paraffin failed with status code: 'BW Rake Task Problem'"
    deleted_file.should == 'someDirectory/some_file.PARAFFIN'
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
    deleted_file = nil
    FileUtils.stub(:rm) do |f|
      deleted_file = f
    end
    File.stub(:exists?).and_return(false)

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception "Paraffin failed with status code: 'BW Rake Task Problem'"
    deleted_file.should be_nil
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
      raise 'Paraffin failed' if commands[0].include?('Paraffin.exe')
    }

    # act
    lambda { task.exectaskpublic }.should raise_exception "Paraffin failed"

    # assert
    @commands[0].should == 'cmd.exe /c mklink /J ".\paraffin_config_aware_symlink" "..\Bin\Release"'
    @commands[1].should == '"someParaffinPath\Paraffin.exe" -update "some_file.wxs" -verbose'
    @commands[2].should == 'rmdir ".\paraffin_config_aware_symlink"'
  end
end