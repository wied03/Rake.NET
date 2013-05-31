require "base"
require "nunit"
require "basetaskmocking"

describe BradyW::Nunit do

  it 'shows correct default command line' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.2\\bin\\nunit-console.exe\" /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'uses NUnit 2.6.1' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.version = "2.6.1"
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.1\\bin\\nunit-console.exe\" /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'uses a configured custom path' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.path = "C:\\SomeOtherplace"
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\SomeOtherplace\\nunit-console.exe\" /framework=4.5 /timeout=35000 file1.dll file2.dll"
  end

  it 'uses a custom timeout' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.timeout = 25
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.2\\bin\\nunit-console.exe\" /framework=4.5 /timeout=25 file1.dll file2.dll"
  end

  it 'uses .NET 3.5' do
    task = BradyW::Nunit.new do |test|
      test.files = ["file1.dll", "file2.dll"]
      test.framework_version = :v3_5
    end
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\Program Files (x86)\\NUnit 2.6.2\\bin\\nunit-console.exe\" /framework=3.5 /timeout=35000 file1.dll file2.dll"
  end
end