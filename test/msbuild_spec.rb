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
    false.should == true
  end
end