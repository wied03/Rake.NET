require "base"
require "msbuild"
require "basetaskmisc"

describe "MSBuild Rake Task" do

  before(:each) do
    # This resets our recorded output
    sh2 "---new test---"    
  end
  
  it "should build OK vanilla" do
    @task = BW::MSBuild.new
    @task.exectaskpublic
    @task.sh.should == "C:\\Windows\\Microsoft.NET\\Framework\\v4.0.21006\\msbuild.exe /property:TargetFrameworkVersion=v4.0;Configuration=Debug"
  end

  it "should build OK with everything customized" do
    @task = BW::MSBuild.new do |t|
      t.targets = ['t1', 't2']
      t.dotnet_bin_version = "3.5"
      t.solution = "solutionhere"
      t.compile_version = "1.0"
      t.properties = {'prop1' => 'prop1val',
                      'prop2' => 'prop2val'}
      t.release = true
    end
    @task.exectaskpublic
    @task.sh.should == "C:\\Windows\\Microsoft.NET\\Framework\\v3.5\\msbuild.exe /target:t1,t2 /property:TargetFrameworkVersion=v1.0;Configuration=Release;prop1=prop1val;prop2=prop2val solutionhere"
  end
end