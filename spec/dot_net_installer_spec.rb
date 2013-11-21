require 'base'
require 'dot_net_installer'
require 'basetaskmocking'

describe BradyW::DotNetInstaller do
  before :each do
    BswTech::DnetInstallUtil.stub(:dot_net_installer_base_path).and_return('path/to/dnetinstaller')
  end

  # TODO: Task 2: DotNetinstaller task.  should do token replace in XML,make a temp copy, then call something like this: "%DNET_INSTALLER_PATH%\InstallerLinker.exe" /c:dotnetinstaller.xml /o:bin\Release\Bsw.Coworking.Agent.Installer.exe /t:"%DNET_INSTALLER_PATH%\dotNetInstaller.exe"

  it 'should render a proper command line' do
    # arrange
    task = BradyW::DotNetInstaller.new do |t|
      t.directory_reference = 'BinDir'
    end

    # act
    task.exectaskpublic
        command = task.executedPop

    # assert
    true.should == false
  end

  it 'should replace tokens in XML properly' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end

  it 'should remove the temporarily generated XML file if an error occurs in the executable' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end
end