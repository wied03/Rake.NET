require "base"
require "mstest"
require "basetaskmocking"

describe BradyW::MSTest do

  it "Should work with default settings" do
    task = BradyW::MSTest.new do |test|
      test.files = ["file1.dll", "file2.dll"]
    end
    task.should_receive(:visual_studio).with("10.0").and_return("C:\\yespath\\")
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\yespath\\MSTest.exe\" /testcontainer:file1.dll /testcontainer:file2.dll"
  end

  it "Should work with custom settings" do
    task = BradyW::MSTest.new do |test|
      test.files = ["file1.dll"]
      test.version = "8.0"
    end
    task.should_receive(:visual_studio).with("8.0").and_return("C:\\yespath2\\")
    task.exectaskpublic
    task.excecutedPop.should == "\"C:\\yespath2\\MSTest.exe\" /testcontainer:file1.dll"    
  end
end