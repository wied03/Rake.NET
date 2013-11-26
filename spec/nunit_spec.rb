require 'base'
require 'nunit'

describe BradyW::Nunit do
  before(:each) do
    File.stub(:exists?).with("C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe").and_return(true)
  end

  it 'throws error when NUnit could not be found' do
    File.stub(:exists?).with("C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe").and_return(false)
    File.stub(:exists?).with("C:/Program Files (x86)/NUnit-2.6.3/bin/nunit-console.exe").and_return(false)

    task = BradyW::Nunit.new do |test|
              test.files = ["file1.dll", "file2.dll"]
    end
    lambda {task.exectaskpublic}.should raise_exception("We checked the following locations and could not find nunit-console.exe [\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\", \"C:/Program Files (x86)/NUnit-2.6.3/bin/nunit-console.exe\"]")
  end

  it 'works when a ZIP file, not an MSI is installed, which has a different path' do
    File.stub(:exists?).with("C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe").and_return(false)
    File.stub(:exists?).with("C:/Program Files (x86)/NUnit-2.6.3/bin/nunit-console.exe").and_return(true)
    task = BradyW::Nunit.new do |test|
          test.files = ["file1.dll", "file2.dll"]
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit-2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'shows correct default command line' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'doesnt test duplicate files' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file1.dll"]
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll"
  end

  it 'uses NUnit 2.6.1' do
    File.stub(:exists?).with("C:/Program Files (x86)/NUnit 2.6.1/bin/nunit-console.exe").and_return(true)
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.version = "2.6.1"
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.1/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'uses a configured custom path' do
    File.stub(:exists?).with("C:\\SomeOtherplace\\nunit-console.exe").and_return(true)
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.path = "C:\\SomeOtherplace\\nunit-console.exe"
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:\\SomeOtherplace\\nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'uses a configured custom path and the console is not found' do
    File.stub(:exists?).with("C:/SomeOtherplace/nunit-console.exe").and_return(false)
      task = BradyW::Nunit.new do |test|
        test.files = ["file1.dll", "file2.dll"]
        test.path = "C:/SomeOtherplace/nunit-console.exe"
      end

      lambda {task.exectaskpublic}.should raise_exception "We checked the following locations and could not find nunit-console.exe [\"C:/SomeOtherplace/nunit-console.exe\"]"
    end

  it 'uses a custom timeout' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.timeout = 25
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=25 file1.dll file2.dll"
  end

  it 'uses .NET 3.5' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.framework_version = :v3_5
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=3.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'can handle a single specific test to run' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.tests = "some.test"
    end

    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 /run=some.test file1.dll file2.dll"
  end

  it 'can handle a multiple specific tests to run' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.tests = ["some.test", "some.other.test"]
    end

    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 /run=some.test,some.other.test file1.dll file2.dll"
  end

  it 'should work OK if XML output is turned on' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.xml_output = :enabled
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /labels /framework=4.5 /timeout=35000 file1.dll file2.dll"

  end

  it 'Should work without labels' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.labels = :exclude_labels
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"

  end

  it 'Should work OK with custom errors and console output' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.output = "somefile.txt"
      test.errors = "someerrorfile.txt"
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console.exe\" /output=somefile.txt /err=someerrorfile.txt /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'Should work OK with x86 arch' do
    File.stub(:exists?).with("C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console-x86.exe").and_return(true)
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.arch = :x86
    end
    task.exectaskpublic
    task.executedPop.should == "\"C:/Program Files (x86)/NUnit 2.6.3/bin/nunit-console-x86.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"

  end
end