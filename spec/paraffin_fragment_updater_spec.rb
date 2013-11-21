require 'base'
require 'paraffin_fragment_updater'
require 'basetaskmocking'

describe BradyW::ParaffinFragmentUpdater do
  before(:each) do
    @mockBasePath = 'someParaffinPath\Paraffin.exe'
    stub_const 'BswTech::DnetInstallUtil::PARAFFIN_EXE', @mockBasePath
  end

  it 'must supply the WXS value' do
    # arrange
    task = BradyW::ParaffinFragmentUpdater.new

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception ':fragment_file is required for this task'
  end

  it 'should work OK when the WXS value is supplied' do
    # arrange
    task = BradyW::ParaffinFragmentUpdater.new do |t|
      t.fragment_file = 'some_file.wxs'
    end

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    command.should == '"someParaffinPath\Paraffin.exe" -update some_file.wxs -verbose'
  end

  it 'should work properly with the ReportIfDifferent flag' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end

  it 'should replace the output file with Paraffin''s generated file if told to do so' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end

  it 'should remove the generated file if we are told to replace it' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end

  it 'should handle an error in Paraffin OK when replacing the generated file' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end

  it 'should handle an error in Paraffin OK when NOT replacing the generated file' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end
end