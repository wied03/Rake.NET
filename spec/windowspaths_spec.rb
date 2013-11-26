require 'base'
require 'windowspaths'

class WindowsPathsWrapper
  include BradyW::WindowsPaths

  def log text
    puts text
  end
end

describe BradyW::WindowsPaths do
  after(:each) do
    BradyW::RegistryAccessor.unstub(:new)
  end

  before(:each) do
    @key = nil
    @value = nil
    @windowPathsWrapper = WindowsPathsWrapper.new
    mock_accessor = BradyW::RegistryAccessor.new
    # No dependency injection framework required :)
    BradyW::RegistryAccessor.stub(:new).and_return(mock_accessor)
    mock_accessor.stub(:reg_value) do |key, value|
      @key = key
      @value = value
      'hi'
    end
  end

  it 'should retrieve SQL Server tools properly' do
    result = @windowPathsWrapper.send(:sql_tool, 'verhere')
    result.should == "hi"
    @key.should == 'SOFTWARE\\Microsoft\\Microsoft SQL Server\\verhere\\Tools\\ClientSetup'
    @value.should == 'Path'
  end

  it 'should retrieve the Visual Studio path properly' do
    result = @windowPathsWrapper.send(:visual_studio, 'verhere')
    result.should == 'hi'
    @key.should == 'SOFTWARE\\Microsoft\\VisualStudio\\verhere'
    @value.should == 'InstallDir'
  end

  it 'should retrieve .NET runtime path properly' do
    result = @windowPathsWrapper.send(:dotnet, 'verhere')
    result.should == 'hi'
    @key.should == 'SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\verhere'
    @value.should == 'InstallPath'
  end

  it 'should retrieve the location of signtool.exe for :x86' do
    # arrange

    # act
    result = @windowPathsWrapper.send(:signtool_exe, :x86)

    # assert
    expect(result).to eq('hi/bin/x86/signtool.exe')
    @key.should == 'SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots'
    @value.should == 'KitsRoot'
  end

  it 'should retrieve the location of signtool.exe for :x64' do
    # arrange

    # act
    result = @windowPathsWrapper.send(:signtool_exe, :x64)

    # assert
    expect(result).to eq('hi/bin/x64/signtool.exe')
    @key.should == 'SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots'
    @value.should == 'KitsRoot'
  end
end