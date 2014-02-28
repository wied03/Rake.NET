require 'spec_helper'

describe BradyW::SignTool do
  before :each do
    @mock_registry = BradyW::RegistryAccessor.new
    # No dependency injection framework required :)
    BradyW::RegistryAccessor.stub(:new).and_return(@mock_registry)
  end

  after(:each) do
    BradyW::RegistryAccessor.unstub(:new)
  end

  it 'should require subject, description, and sign_this' do
    # arrange
    task = BradyW::SignTool.new

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception ':subject, :description, and :sign_this are required'
  end

  it 'should execute properly with a lower version of the windows SDK' do
    # arrange
    task = BradyW::SignTool.new do |t|
      t.subject = 'The Subject'
      t.description = 'The description'
      t.sign_this = 'something.exe'
    end
    @mock_registry.stub(:get_sub_keys).with('SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows').and_return(['v7.1A', 'v8.0', 'v8.1A'])
    @mock_registry.stub(:get_value).with('SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v8.0', 'InstallationFolder').and_return('path/to')

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    command.should == '"path/to/bin/x64/signtool.exe" sign /n "The Subject" /t http://timestamp.verisign.com/scripts/timestamp.dll /d "The description" "something.exe"'
  end

  it 'should execute properly with a certificate in the certificate store and default timestamp' do
    # arrange
    task = BradyW::SignTool.new do |t|
      t.subject = 'The Subject'
      t.description = 'The description'
      t.sign_this = 'something.exe'
    end
    @mock_registry.stub(:get_sub_keys).with('SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows').and_return(['v7.1A', 'v8.0A', 'v8.1A', 'v8.1'])
    @mock_registry.stub(:get_value).with('SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v8.1', 'InstallationFolder').and_return('path/to')

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    command.should == '"path/to/bin/x64/signtool.exe" sign /n "The Subject" /t http://timestamp.verisign.com/scripts/timestamp.dll /d "The description" "something.exe"'
  end

  it 'should work properly with a custom timestamp, SDK version, and custom architecture' do
    # arrange
    task = BradyW::SignTool.new do |t|
      t.subject = 'The Subject'
      t.description = 'The description'
      t.sign_this = 'something.exe'
      t.timestamp_url = 'http://something/timestamp.dll'
      t.sdk_version = '8.2A'
      t.architecture = :x86
    end
    @mock_registry.stub(:get_value).with('SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v8.2A', 'InstallationFolder').and_return('path/to')

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    command.should == '"path/to/bin/x86/signtool.exe" sign /n "The Subject" /t http://something/timestamp.dll /d "The description" "something.exe"'
  end
end