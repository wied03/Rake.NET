require "base"
require "msbuild"
require "basetaskmisc"

describe "Task: MSBuild" do

  it "should build OK vanilla" do
    task = BW::MSBuild.new
    task.should_receive(:dotnet).with("4.0").and_return("C:\\yespath\\")
    task.exectaskpublic
    task.excecutedPop.should == "C:\\yespath\\msbuild.exe /property:TargetFrameworkVersion=v4.0;Configuration=Debug"
  end

  it "should build OK with everything customized" do
    task = BW::MSBuild.new do |t|
      t.targets = ['t1', 't2']
      t.dotnet_bin_version = "3.5"
      t.solution = "solutionhere"
      t.compile_version = "1.0"
      t.properties = {'prop1' => 'prop1val',
                      'prop2' => 'prop2val'}
      t.release = true
    end
    task.should_receive(:dotnet).with("3.5").and_return("C:\\yespath2\\")
    task.exectaskpublic
    task.excecutedPop.should == "C:\\yespath2\\msbuild.exe /target:t1,t2 /property:TargetFrameworkVersion=v1.0;Configuration=Release;prop1=prop1val;prop2=prop2val solutionhere"
  end
end