require 'base'
require 'dot_net_installer'

describe BradyW::DotNetInstaller do
  before :each do
    @should_delete = 'generated_name.xml'
    BswTech::DnetInstallUtil.stub(:dot_net_installer_base_path).and_return('path/to/dnetinstaller')
    BradyW::TempFileNameGenerator.stub(:filename).and_return 'generated_name.xml'
    ENV['PRESERVE_TEMP'] = nil
  end

  after :each do
    rm @should_delete if (@should_delete && File.exists?(@should_delete))
  end

  it 'should render a proper command line' do
    # arrange
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'data/dot_net_installer/input.xml'
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

  it 'should handle symbols as token values' do
    # arrange
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'data/dot_net_installer/input.xml'
      t.output = 'somedir/Our.File.Exe'
      t.tokens = {:token1 => 'value1',
                  :token2 => :some_value}
    end
    # Leave the temp file so we can compare it
    FileUtils.stub(:rm) do |f|
      @should_delete = f
    end

    # act
    task.exectaskpublic

    # assert
    expected = IO.readlines('data/dot_net_installer/expected_output_symbol.xml')
    actual = IO.readlines(@should_delete)
    actual.should == expected
  end

  it 'should replace tokens in XML properly' do
    # arrange
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'data/dot_net_installer/input.xml'
      t.output = 'somedir/Our.File.Exe'
      t.tokens = {:token1 => 'value1',
                  :token2 => 'value2'}
    end
    # Leave the temp file so we can compare it
    FileUtils.stub(:rm) do |f|
      @should_delete = f
    end

    # act
    task.exectaskpublic

    # assert
    expected = IO.readlines('data/dot_net_installer/expected_output.xml')
    actual = IO.readlines(@should_delete)
    actual.should == expected
  end

  it 'should remove the temporarily generated XML file' do
    # arrange
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'data/dot_net_installer/input.xml'
      t.output = 'somedir/Our.File.Exe'
    end

    # act
    task.exectaskpublic

    # assert
    File.should_not be_exist(@should_delete)
  end

  it 'should leave the temporarily generated XML file around if PRESERVE_TEMP env is set' do
    # arrange
    ENV['PRESERVE_TEMP'] = 'true'
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'data/dot_net_installer/input.xml'
      t.output = 'somedir/Our.File.Exe'
    end

    # act
    task.exectaskpublic

    # assert
    File.should be_exist(@should_delete)
  end

  it 'should remove the temporarily generated XML file even if an error occurs in the executable' do
    # arrange
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'data/dot_net_installer/input.xml'
      t.output = 'somedir/Our.File.Exe'
    end
    task.stub(:shell).and_yield(nil, SimulateProcessFailure.new)

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception "Problem with dotNetInstaller.  Return code 'BW Rake Task Problem'"
    File.should_not be_exist(@should_delete)
  end
end