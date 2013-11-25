require 'base'
require 'paraffin/fragment_updater'
require 'basetaskmocking'

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
    lambda { task.exectaskpublic }.should raise_exception ':fragment_file is required for this task'
  end

  it 'should work OK when the WXS value is supplied and replace original is off' do
    # arrange
    task = BradyW::Paraffin::FragmentUpdater.new do |t|
      t.fragment_file = 'some_file.wxs'
      t.replace_original = false
    end
    FileUtils.stub(:rm).and_throw 'Should not be removing any files'

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    command.should == '"someParaffinPath\Paraffin.exe" -update "some_file.wxs" -verbose -ReportIfDifferent'
  end

  it 'should work properly with the ReportIfDifferent error codes from Paraffin' do
    # arrange
    task = BradyW::Paraffin::FragmentUpdater.new do |t|
      t.fragment_file = 'some_file.wxs'
      t.replace_original = false
    end
    task.stub(:shell).and_yield(nil, ParaffinReportDifferentError.new)
    FileUtils.stub(:rm).and_throw 'Should not be removing any files'

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception 'some_file.wxs has changed and you don\'t have :replace_original enabled.  Manually update some_file.wxs using ./some_file.PARAFFIN or enable :replace_original'
  end

  it 'should replace the output file with Paraffin' 's generated file if told to do so' do
    # arrange
    task = BradyW::Paraffin::FragmentUpdater.new do |t|
      t.fragment_file = 'someDirectory/some_file.wxs'
    end
    original_file = nil
    destination_file = nil
    FileUtils.stub(:mv) do |orig, dest|
      original_file = orig
      destination_file = dest
    end

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    command.should == '"someParaffinPath\Paraffin.exe" -update "someDirectory/some_file.wxs" -verbose'
    original_file.should == 'someDirectory/some_file.PARAFFIN'
    destination_file.should == 'someDirectory/some_file.wxs'
  end

  it 'should handle an error in Paraffin OK when replacing the generated file (if Paraffin generated the file)' do
    # arrange
    task = BradyW::Paraffin::FragmentUpdater.new do |t|
      t.fragment_file = 'someDirectory/some_file.wxs'
    end
    task.stub(:shell).and_yield(nil, SimulateProcessFailure.new)
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
    end
    task.stub(:shell).and_yield(nil, SimulateProcessFailure.new)
    deleted_file = nil
    FileUtils.stub(:rm) do |f|
      deleted_file = f
    end
    File.stub(:exists?).and_return(false)

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception "Paraffin failed with status code: 'BW Rake Task Problem'"
    deleted_file.should be_nil
  end
end