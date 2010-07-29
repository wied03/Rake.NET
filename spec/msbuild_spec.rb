require "base"
require "msbuild"
require "basetaskmocking"

describe BW::MSBuild do

  it "should build OK vanilla (.NET 4.0)" do
    task = BW::MSBuild.new
    task.should_receive(:dotnet).with("v4\\Client").and_return("C:\\yespath\\")
    task.exectaskpublic
    task.excecutedPop.should == "C:\\yespath\\msbuild.exe /property:TargetFrameworkVersion=v4.0;Configuration=Debug"
  end

  it "should fail with an unsupported dotnet_bin_version" do
    task = BW::MSBuild.new do |t|
      t.dotnet_bin_version = :v2_25
    end
    lambda {task.exectaskpublic}.should raise_exception("You supplied a .NET MSBuild binary version that's not supported.  Please use :v4_0, :v3_5, or :v2_0")
  end

  it "should build OK with a single target" do
    task = BW::MSBuild.new do |t|
      t.targets = 't1'
    end
    
    task.should_receive(:dotnet).with("v4\\Client").and_return("C:\\yespath\\")
    task.exectaskpublic
    task.excecutedPop.should == "C:\\yespath\\msbuild.exe /target:t1 /property:TargetFrameworkVersion=v4.0;Configuration=Debug"
  end

  it "should build OK with everything customized (.NET 3.5)" do
    task = BW::MSBuild.new do |t|
      t.targets = ['t1', 't2']
      t.dotnet_bin_version = :v3_5
      t.solution = "solutionhere"
      t.compile_version = :v3_5
      t.properties = {'prop1' => 'prop1val',
                      'prop2' => 'prop2val'}
      t.release = true
    end
    task.should_receive(:dotnet).with("v3.5").and_return("C:\\yespath2\\")
    task.exectaskpublic
    task.excecutedPop.should == "C:\\yespath2\\msbuild.exe /target:t1,t2 /property:TargetFrameworkVersion=v3.5;Configuration=Release;prop1=prop1val;prop2=prop2val solutionhere"
  end

  it "should build OK with custom properties that are also defaults (.NET 4.0)" do
    task = BW::MSBuild.new do |t|
      t.properties = {'Configuration' => 'myconfig',
                      'prop2' => 'prop2val'}
      t.release = true
    end
    task.should_receive(:dotnet).with("v4\\Client").and_return("C:\\yespath2\\")
    task.exectaskpublic
    task.excecutedPop.should == "C:\\yespath2\\msbuild.exe /property:TargetFrameworkVersion=v4.0;Configuration=myconfig;prop2=prop2val"
  end

  it "should build OK with .NET 2.0" do
    task = BW::MSBuild.new do |t|
       t.dotnet_bin_version = :v2_0
       t.compile_version = :v2_0
    end
    task.exectaskpublic
    task.excecutedPop.should == "C:\\Windows\\Microsoft.NET\\Framework\\v2.0.50727\\msbuild.exe /property:TargetFrameworkVersion=v2.0;Configuration=Debug"
  end
end