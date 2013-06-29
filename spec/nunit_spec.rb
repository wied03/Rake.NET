require "base"
require "nunit"
require "basetaskmocking"

describe BradyW::Nunit do

  it 'shows correct default command line' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.2\\bin\\nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'doesnt test duplicate files' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file1.dll"]
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.2\\bin\\nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll"
  end

  it 'uses NUnit 2.6.1' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.version = "2.6.1"
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.1\\bin\\nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'uses a configured custom path' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.path = "C:\\SomeOtherplace"
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\SomeOtherplace\\nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'uses a custom timeout' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.timeout = 25
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.2\\bin\\nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=25 file1.dll file2.dll"
  end

  it 'uses .NET 3.5' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.framework_version = :v3_5
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.2\\bin\\nunit-console.exe\" /labels /noxml /framework=3.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'can handle a single specific test to run' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.tests = "some.test"
    end

    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.2\\bin\\nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 /run=some.test file1.dll file2.dll"
  end

  it 'can handle a multiple specific tests to run' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.tests = ["some.test", "some.other.test"]
    end

    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.2\\bin\\nunit-console.exe\" /labels /noxml /framework=4.5 /timeout=35000 /run=some.test,some.other.test file1.dll file2.dll"
  end

  it 'should work OK if XML output is turned on' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.xml_output = :enabled
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.2\\bin\\nunit-console.exe\" /labels /framework=4.5 /timeout=35000 file1.dll file2.dll"

  end

  it 'Should work without labels' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.labels = :exclude_labels
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.2\\bin\\nunit-console.exe\" /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"

  end

  it 'Should work OK with custom errors and console output' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.output = "somefile.txt"
      test.errors = "someerrorfile.txt"
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.2\\bin\\nunit-console.exe\" /output=somefile.txt /err=someerrorfile.txt /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'Should work OK with x86 arch' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.arch = :x86
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.2\\bin\\nunit-console-x86.exe\" /labels /noxml /framework=4.5 /timeout=35000 file1.dll file2.dll"

  end
end