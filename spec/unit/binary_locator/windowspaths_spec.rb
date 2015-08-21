require 'spec_helper'

class WindowsPathsWrapper
  include BradyW::WindowsPaths

  def log text
    puts text
  end
end

describe BradyW::WindowsPaths do
  before(:each) do
    @key = nil
    @value = nil
    @windowPathsWrapper = WindowsPathsWrapper.new
    mock_accessor = BradyW::RegistryAccessor.new
    # No dependency injection framework required :)
    allow(BradyW::RegistryAccessor).to receive(:new).and_return(mock_accessor)
    allow(mock_accessor).to receive(:get_value) do |key, value|
      @key = key
      @value = value
      'hi'
    end
    @mock_msi_searcher = BradyW::MsiFileSearcher.new
    allow(BradyW::MsiFileSearcher).to receive(:new).and_return(@mock_msi_searcher)
  end

  it 'should retrieve SQL Server tools properly' do
    result = @windowPathsWrapper.send(:sql_tool, 'verhere')
    result.should == 'hi'
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

  it 'should retrieve the path of subinacl' do
    # arrange
    allow(@mock_msi_searcher).to receive(:get_component_path).with('{D3EE034D-5B92-4A55-AA02-2E6D0A6A96EE}','{C2BC2826-FDDC-4A61-AA17-B3928B0EDA38}').and_return('path\to\subinacl.exe')

    # act
    result = @windowPathsWrapper.send(:subinacl_path)

    # assert
    result.should == 'path\to\subinacl.exe'
  end
end
