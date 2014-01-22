require 'base'
require 'nunit'

describe BradyW::Nunit do
  before(:each) do
    ENV['nunit_filelist'] = nil
    FileUtils.rm 'something.txt' if File.exists?('something.txt')
    File.stub(:exists?).with('C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe').and_return(true)
    @should_deletes = ['generated_name_1.xml', 'generated_name_2.xml']
    @file_index = 0
    BradyW::TempFileNameGenerator.stub(:random_filename) {
      @file_index += 1
      "generated_name_#{@file_index}.xml"
    }
  end

  after(:each) do
    begin
     File.delete 'something.txt'
    rescue
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
    File.stub(:exists?).with("C:\\SomeOtherplace\\nunit-console.exe").and_return(true)
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.path = 'C:\\SomeOtherplace\\nunit-console.exe'
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:\\SomeOtherplace\\nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'uses a configured custom path and the console is not found' do
    File.stub(:exists?).with("C:/SomeOtherplace/nunit-console.exe").and_return(false)
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.path = 'C:/SomeOtherplace/nunit-console.exe'
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
    ENV['nunit_filelist'] = 'nun*_spec.rb'
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
    end

    # act
    task.exectaskpublic

    # assert
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 nunit_spec.rb"
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
    File.open 'generated_name_1.xml', 'w' do |f|
      f << 'stuff from nunit'
    end
    console_text = []
    task.stub(:log) { |text| console_text << text }

    # act
    task.exectaskpublic

    # assert
    task.executedPop.should == "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"C:\\Program Files (x86)\\NUnit 2.6.3\\bin\\nunit-console.exe\" /output=generated_name_1.xml /labels /framework=4.5 /timeout=35000 file1.dll file2.dll"
    expect(console_text).to include('stuff from nunit')
    File.should_not be_exist(@should_deletes[0])
  end

  it 'should allow the output file to be overridden in elevated mode' do
    # arrange
    task = BradyW::Nunit.new do |test|
      test.files = %w(file1.dll file2.dll)
      test.security_mode = :elevated
      test.output = 'something.txt'
    end
    File.open 'something.txt', 'w' do |f|
      f << 'stuff from nunit'
    end
    console_text = []
    task.stub(:log) { |text| console_text << text }

    # act
    task.exectaskpublic

    # assert
    task.executedPop.should == "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"C:\\Program Files (x86)\\NUnit 2.6.3\\bin\\nunit-console.exe\" /output=something.txt /labels /framework=4.5 /timeout=35000 file1.dll file2.dll"
    expect(console_text).to include('stuff from nunit')
    File.should be_exist('something.txt')
  end
end