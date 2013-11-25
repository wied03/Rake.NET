require "base"
require "windowspaths"

class WindowsPathsWrapper
  include BradyW::WindowsPaths
  def log text
    puts text
  end
end

describe BradyW::WindowsPaths do
  before(:each) do
    @windowPathsWrapper = WindowsPathsWrapper.new
    @mockedRegistryAccessor = BradyW::RegistryAccessor.new
    # No dependency injection framework required :)
    BradyW::RegistryAccessor.stub(:new).and_return(@mockedRegistryAccessor)
  end

  it "should retrieve SQL Server tools properly" do
    @mockedRegistryAccessor.should_receive(:regvalue).with("SOFTWARE\\Microsoft\\Microsoft SQL Server\\verhere\\Tools\\ClientSetup",
                                                                "Path").and_return("hi")
    result = @windowPathsWrapper.send(:sql_tool,"verhere")
    result.should == "hi"
  end

  it "should retrieve the Visual Studio path properly" do
    @mockedRegistryAccessor.should_receive(:regvalue).with("SOFTWARE\\Microsoft\\VisualStudio\\verhere",
                                                                "InstallDir").and_return("hi")
    result = @windowPathsWrapper.send(:visual_studio,"verhere")
    result.should == "hi"
  end

  it "should retrieve .NET runtime path properly" do
    @mockedRegistryAccessor.should_receive(:regvalue).with("SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\verhere",
                                                                "InstallPath").and_return("hi")
    result = @windowPathsWrapper.send(:dotnet,"verhere")
    result.should == "hi"
  end
end