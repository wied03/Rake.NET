require 'base'
require 'sign_tool'

describe BradyW::SignTool do
  it 'should require subject, description, and sign_this' do
    # arrange
    task = BradyW::SignTool.new

    # act + assert
    lambda {task.exectaskpublic}.should raise_exception ':subject, :description, and :sign_this are required'
  end

  it 'should execute properly with a certificate in the certificate store and default timestamp' do
    # arrange
    task = BradyW::SignTool.new do |t|
      t.subject = 'The Subject'
      t.description = 'The description'
      t.sign_this = 'something.exe'
    end
    task.stub(:signtool_exe).with(:x64).and_return('path/to/x64/signtool.exe')

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    command.should == 'path/to/x64/signtool.exe sign /n "The Subject" /t http://timestamp.verisign.com/scripts/timestamp.dll /d "The description" "something.exe"'
  end

  it 'should work properly with a custom timestamp and custom architecture' do
    # arrange
    task = BradyW::SignTool.new do |t|
      t.subject = 'The Subject'
      t.description = 'The description'
      t.sign_this = 'something.exe'
      t.timestamp_url = 'http://something/timestamp.dll'
      t.architecture = :x86
    end
    task.stub(:signtool_exe).with(:x86).and_return('path/to/x86/signtool.exe')

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    command.should == 'path/to/x86/signtool.exe sign /n "The Subject" /t http://something/timestamp.dll /d "The description" "something.exe"'
  end
end