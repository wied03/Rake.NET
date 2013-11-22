require 'base'
require 'msbuild'
require 'basetaskmocking'

describe BradyW::MSBuild do
  RSpec::Matchers.define :have_build_property do |expected|
    match do |actual|
      actualProps = parseProps actual
      actualProps.include? expected
    end

    def parseProps (actual)
        actualProps = actual.match(/\/property:(\S+)/)[1].split(';').map do |kv|
        arr = kv.split('=')
        {:k => arr[0], :v =>arr[1]}
        end
        actualProps
    end
  end

  RSpec::Matchers.define :have_build_property_count do |expected|
    match do |actual|
      actualProps = parseProps actual
      actualProps.should have(expected).items
    end

    def parseProps (actual)
        actual.match(/\/property:(\S+)/)[1].split(';')
    end
  end

  it "should build OK vanilla (.NET 4.5)" do
    task = BradyW::MSBuild.new
    task.should_receive(:dotnet).with("v4\\Client").and_return("C:\\yespath\\")
    task.exectaskpublic
    execed = task.executedPop
    execed.should include "C:\\yespath\\msbuild.exe"
    execed.should have_build_property ({:k => "Configuration", :v => "Debug"})
    execed.should have_build_property ({:k => "TargetFrameworkVersion", :v => "v4.5"})
    execed.should have_build_property_count 2
  end

  it "should build OK (.NET 4.0)" do
      task = BradyW::MSBuild.new do |t|
        t.dotnet_bin_version = :v4_0
        t.compile_version = :v4_0
      end
      task.should_receive(:dotnet).with("v4\\Client").and_return("C:\\yespath\\")
      task.exectaskpublic
      execed = task.executedPop
      execed.should include "C:\\yespath\\msbuild.exe"
      execed.should have_build_property ({:k => "Configuration", :v => "Debug"})
      execed.should have_build_property ({:k => "TargetFrameworkVersion", :v => "v4.0"})
      execed.should have_build_property_count 2
    end

  it "should fail with an unsupported dotnet_bin_version" do
    task = BradyW::MSBuild.new do |t|
      t.dotnet_bin_version = :v2_25
    end
    lambda {task.exectaskpublic}.should raise_exception("You supplied a .NET MSBuild binary version that's not supported.  Please use :v4_0, :v3_5, or :v2_0")
  end

  it "should build OK with a single target" do
    task = BradyW::MSBuild.new do |t|
      t.targets = 't1'
    end
    
    task.should_receive(:dotnet).with("v4\\Client").and_return("C:\\yespath\\")
    task.exectaskpublic
    execed = task.executedPop
    execed.should include "C:\\yespath\\msbuild.exe /target:t1"
    execed.should have_build_property ({:k => "Configuration", :v => "Debug"})
    execed.should have_build_property ({:k => "TargetFrameworkVersion", :v => "v4.5"})
    execed.should have_build_property_count 2
  end

  it "should build OK with everything customized (.NET 3.5)" do
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
    task.exectaskpublic
    execed = task.executedPop
    execed.should have_build_property ({:k => "Configuration", :v => "Release"})
    execed.should have_build_property ({:k => "TargetFrameworkVersion", :v => "v3.5"})
    execed.should have_build_property ({:k => "prop1", :v => "prop1val"})
    execed.should have_build_property ({:k => "prop2", :v => "prop2val"})
    execed.should have_build_property_count 4
    execed.should match(/C:\\yespath2\\msbuild\.exe \/target:t1,t2 .* solutionhere/)
  end

  it "should build OK with custom properties that are also defaults (.NET 4.0)" do
    task = BradyW::MSBuild.new do |t|
      t.properties = {'Configuration' => 'myconfig',
                      'prop2' => 'prop2val'}
      t.release = true
    end
    task.should_receive(:dotnet).with("v4\\Client").and_return("C:\\yespath2\\")
    task.exectaskpublic
    execed = task.executedPop
    execed.should include "C:\\yespath2\\msbuild.exe"
    execed.should have_build_property ({:k => "Configuration", :v => "myconfig"})
    execed.should have_build_property ({:k => "TargetFrameworkVersion", :v => "v4.5"})
    execed.should have_build_property ({:k => "prop2", :v => "prop2val"})
    execed.should have_build_property_count 3
  end

  it "should build OK with .NET 2.0" do
    task = BradyW::MSBuild.new do |t|
       t.dotnet_bin_version = :v2_0
       t.compile_version = :v2_0
    end
    task.exectaskpublic
    execed = task.executedPop
    execed.should include "C:\\Windows\\Microsoft.NET\\Framework\\v2.0.50727\\msbuild.exe"
    execed.should have_build_property ({:k => "Configuration", :v => "Debug"})
    execed.should have_build_property ({:k => "TargetFrameworkVersion", :v => "v2.0"})
    execed.should have_build_property_count 2
  end
end