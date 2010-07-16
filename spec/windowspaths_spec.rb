require "base"
require "windowspaths"

class PathTester
  include BW::WindowsPaths
  def sql_tool_pub version
    sql_tool version
  end

  def visual_studio_pub version
    visual_studio version
  end

  def dotnet_pub subpath
    dotnet subpath
  end

  def log text
    puts text
  end
end

describe "Windows Paths" do
  before(:each) do
    @p = PathTester.new
  end

  it "should retrieve SQL Server tools properly" do
    @p.should_receive(:regvalue).any_number_of_times.with("SOFTWARE\\Microsoft\\Microsoft SQL Server\\verhere\\Tools\\ClientSetup",
                                                          "Path").and_return("hi")
    result = @p.sql_tool_pub "verhere"
    result.should == "hi"
  end

  it "should retrieve the Visual Studio path properly" do
    @p.should_receive(:regvalue).any_number_of_times.with("SOFTWARE\\Microsoft\\VisualStudio\\verhere",
                                                          "InstallDir").and_return("hi")
    result = @p.visual_studio_pub "verhere"
    result.should == "hi"
  end

  it "should retrieve .NET runtime path properly" do
    @p.should_receive(:regvalue).any_number_of_times.with("SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\verhere",
                                                          "InstallPath").and_return("hi")
    result = @p.dotnet_pub "verhere"
    result.should == "hi"
  end

  it "should work OK with a 64 bit registry call" do
    @p.should_receive(:regvalue64).any_number_of_times.with("SOFTWARE\\Microsoft\\VisualStudio\\verhere",
                                                            "InstallDir").and_return("hi")
    @p.stub!(:regvalue32).and_return("not me")
    result = @p.visual_studio_pub "verhere"
    result.should == "hi"
  end

  it "should use standard 32 bit registry mode if 64 fails" do
     @p.stub!(:regvalue64).and_raise("Registry failure")
     @p.should_receive(:regvalue32).any_number_of_times.with("SOFTWARE\\Microsoft\\VisualStudio\\verhere",
                                                            "InstallDir").and_return("hi")
     result = @p.visual_studio_pub "verhere"
     result.should == "hi"
  end

  it "should fail if the 32 bit call fails after trying 64" do
     @p.stub!(:regvalue64).and_raise("Registry failure")
     @p.stub!(:regvalue32).and_raise("Registry failure")
     lambda {@p.visual_studio_pub "verhere"}.should raise_exception("Unable to find registry value in either 32 or 64 bit mode: SOFTWARE\\Microsoft\\VisualStudio\\verhere\\InstallDir")
  end
end