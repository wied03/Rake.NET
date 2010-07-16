require "base"
require "windowspaths"

class PathTester
  include BW::WindowsPaths
  def log text
    puts text
  end
end

describe "Windows Paths" do
  before(:each) do
    @p = PathTester.new
    @regmock = BW::RegistryAccessor.new
    BW::RegistryAccessor.stub!(:new).and_return(@regmock)
  end

  it "should retrieve SQL Server tools properly" do
    @regmock.should_receive(:regvalue).any_number_of_times.with("SOFTWARE\\Microsoft\\Microsoft SQL Server\\verhere\\Tools\\ClientSetup",
                                                                "Path").and_return("hi")
    result = @p.send(:sql_tool,"verhere")
    result.should == "hi"
  end

  it "should retrieve the Visual Studio path properly" do
    @regmock.should_receive(:regvalue).any_number_of_times.with("SOFTWARE\\Microsoft\\VisualStudio\\verhere",
                                                                "InstallDir").and_return("hi")
    result = @p.send(:visual_studio,"verhere")
    result.should == "hi"
  end

  it "should retrieve .NET runtime path properly" do
    @regmock.should_receive(:regvalue).any_number_of_times.with("SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\verhere",
                                                                "InstallPath").and_return("hi")
    result = @p.send(:dotnet,"verhere")
    result.should == "hi"
  end
end