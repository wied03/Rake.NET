require 'base'
require 'dot_net_installer'
require 'basetaskmocking'

describe BradyW::DotNetInstaller do
  before :each do
    @should_delete = nil
    BswTech::DnetInstallUtil.stub(:dot_net_installer_base_path).and_return('path/to/dnetinstaller')
    BradyW::TempXmlFileNameGenerator.stub(:filename).and_return 'generated_name.xml'
  end

  after :each do
    FileUtils.rspec_reset
    rm @should_delete if @should_delete
  end

  it 'should generate a valid filename' do
    # arrange
    BradyW::TempXmlFileNameGenerator.rspec_reset
    orig_file = '../dotnetinstaller.xml'

    # act
    @should_delete = BradyW::TempXmlFileNameGenerator.filename orig_file
    puts "Got filename #{@should_delete}, trying to create to ensure it's a valid filename"
    FileUtils.touch @should_delete
  end

  # TODO: Task 2: DotNetinstaller task.  should do token replace in XML,make a temp copy, then call something like this: "%DNET_INSTALLER_PATH%\InstallerLinker.exe" /c:dotnetinstaller.xml /o:bin\Release\Bsw.Coworking.Agent.Installer.exe /t:"%DNET_INSTALLER_PATH%\dotNetInstaller.exe"

  it 'should render a proper command line' do
    # arrange
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'somedir/dotnetinstaller.xml'
      t.output = 'somedir/Our.File.Exe'
    end

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    command.should == '"path/to/dnetinstaller/Bin/InstallerLinker.exe" /c:"generated_name.xml" /o:"somedir/Our.File.Exe" /t:"path/to/dnetinstaller/Bin/dotNetInstaller.exe"'
  end

  it 'should require xml_config and output' do
    # arrange
    task = BradyW::DotNetInstaller.new

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception ':xml_config and :output are required'
  end

  it 'should replace tokens in XML properly' do
    # arrange
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'somedir/dotnetinstaller.xml'
      t.output = 'somedir/Our.File.Exe'
    end
    # Leave the temp file so we can compare it
    FileUtils.stub(:rm) do |f|
      @should_delete = f
    end

    # act
    task.exectaskpublic

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