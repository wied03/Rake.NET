require 'base'
require 'msbuild'

describe BradyW::MSBuild do
  it 'should build OK vanilla (.NET 4.5)' do
    # arrange
    task = BradyW::MSBuild.new
    task.should_receive(:dotnet).with("v4\\Client").and_return("C:\\yespath\\")

    # act
    task.exectaskpublic
    execed = task.executedPop

    # assert
    execed.should == 'C:\\yespath\\msbuild.exe /property:Configuration=Debug /property:TargetFrameworkVersion=v4.5'
  end

  it 'should work OK with spaces in property value' do
    # arrange
    task = BradyW::MSBuild.new do |m|
      m.properties = {:prop1 => 'the value'}
      m.solution = 'stuff.sln'
    end
    task.should_receive(:dotnet).with("v4\\Client").and_return("C:\\yespath\\")

    # act
    task.exectaskpublic
    execed = task.executedPop

    # assert
    execed.should include '/property:Configuration=Debug /property:TargetFrameworkVersion=v4.5 /property:prop1="the value"'
  end

  it "should build OK (.NET 4.0)" do
    task = BradyW::MSBuild.new do |t|
      t.dotnet_bin_version = :v4_0
      t.compile_version = :v4_0
    end
    task.should_receive(:dotnet).with("v4\\Client").and_return("C:\\yespath\\")
    task.exectaskpublic
    execed = task.executedPop
    execed.should == 'C:\\yespath\\msbuild.exe /property:Configuration=Debug /property:TargetFrameworkVersion=v4.0'
  end

  it "should fail with an unsupported dotnet_bin_version" do
    task = BradyW::MSBuild.new do |t|
      t.dotnet_bin_version = :v2_25
    end
    lambda { task.exectaskpublic }.should raise_exception("You supplied a .NET MSBuild binary version that's not supported.  Please use :v4_0, :v3_5, or :v2_0")
  end

  it "should build OK with a single target" do
    # arrange
    task = BradyW::MSBuild.new do |t|
      t.targets = 't1'
    end
    task.should_receive(:dotnet).with("v4\\Client").and_return("C:\\yespath\\")

    # act
    task.exectaskpublic
    execed = task.executedPop

    # assert
    execed.should == 'C:\\yespath\\msbuild.exe /target:t1 /property:Configuration=Debug /property:TargetFrameworkVersion=v4.5'
  end

  it "should build OK with everything customized (.NET 3.5)" do
    # arrange
    task = BradyW::MSBuild.new do |t|
      t.targets = ['t1', 't2']
      t.dotnet_bin_version = :v3_5
      t.solution = "solutionhere"
      t.compile_version = :v3_5
      t.properties = {'prop1' => 'prop1val',
                      'prop2' => 'prop2val'}
      t.release = true
    end
    task.should_receive(:dotnet).with("v3.5").and_return("C:\\yespath2\\")

    # act
    task.exectaskpublic
    execed = task.executedPop

    # assert
    execed.should == 'C:\\yespath2\\msbuild.exe /target:t1 /target:t2 /property:Configuration=Release /property:TargetFrameworkVersion=v3.5 /property:prop1=prop1val /property:prop2=prop2val solutionhere'
  end

  it "should build OK with custom properties that are also defaults (.NET 4.0)" do
    # arrange
    task = BradyW::MSBuild.new do |t|
      t.properties = {:Configuration => 'myconfig',
                      :prop2 => 'prop2val'}
      t.release = true
    end
    task.should_receive(:dotnet).with("v4\\Client").and_return("C:\\yespath2\\")

    # act
    task.exectaskpublic
    execed = task.executedPop

    # assert
    execed.should == 'C:\\yespath2\\msbuild.exe /property:Configuration=myconfig /property:TargetFrameworkVersion=v4.5 /property:prop2=prop2val'
  end

  it "should build OK with .NET 2.0" do
    # arrange
    task = BradyW::MSBuild.new do |t|
      t.dotnet_bin_version = :v2_0
      t.compile_version = :v2_0
    end

    # act
    task.exectaskpublic
    execed = task.executedPop

    # assert
    execed.should == 'C:\\Windows\\Microsoft.NET\\Framework\\v2.0.50727\\msbuild.exe /property:Configuration=Debug /property:TargetFrameworkVersion=v2.0'
  end
end