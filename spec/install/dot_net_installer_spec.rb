require 'base'

describe BradyW::DotNetInstaller do
  before :each do
    @should_deletes = ['generated_name_1.xml', 'generated_name_2.xml']
    BswTech::DnetInstallUtil.stub(:dot_net_installer_base_path).and_return('path/to/dnetinstaller')
    @file_index = 0
    BradyW::TempFileNameGenerator.stub(:from_existing_file) {
      @file_index += 1
      "generated_name_#{@file_index}.xml"
    }
    ENV['PRESERVE_TEMP'] = nil
  end

  after :each do
    @should_deletes.each { |f| rm f if (f && File.exists?(f)) }
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
    command.should == '"path/to/dnetinstaller/Bin/InstallerLinker.exe" /c:"generated_name_1.xml" /o:"somedir/Our.File.Exe" /t:"path/to/dnetinstaller/Bin/dotNetInstaller.exe"'
  end

  it 'should work properly with a specified manifest file' do
    # arrange
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'data/dot_net_installer/input.xml'
      t.output = 'somedir/Our.File.Exe'
      t.manifest = 'data/dot_net_installer/input_manifest.xml'
    end

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    command.should == '"path/to/dnetinstaller/Bin/InstallerLinker.exe" /c:"generated_name_1.xml" /o:"somedir/Our.File.Exe" /t:"path/to/dnetinstaller/Bin/dotNetInstaller.exe" /Manifest:"generated_name_2.xml"'
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

  it 'should replace tokens in core XML properly' do
    # arrange
    # Leave the temp file so we can compare it
    ENV['PRESERVE_TEMP'] = 'true'
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'data/dot_net_installer/input.xml'
      t.output = 'somedir/Our.File.Exe'
      t.tokens = {:token1 => 'value1',
                  :token2 => 'value2'}
    end

    # act
    task.exectaskpublic

    # assert
    expected = IO.readlines('data/dot_net_installer/expected_output.xml')
    actual = IO.readlines(@should_deletes[0])
    actual.should == expected
  end

  it 'should replace tokens in manifest properly' do
    # arrange
    # Leave the temp file so we can compare it
    ENV['PRESERVE_TEMP'] = 'true'
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'data/dot_net_installer/input.xml'
      t.manifest = 'data/dot_net_installer/input_manifest.xml'
      t.output = 'somedir/Our.File.Exe'
      t.tokens = {:token1 => 'value1',
                  :token2 => 'value2'}
    end

    # act
    task.exectaskpublic

    # assert
    expected = IO.readlines('data/dot_net_installer/expected_manifest.xml')
    actual = IO.readlines(@should_deletes[1])
    actual.should == expected
  end

  it 'should remove the temporarily generated core XML file' do
    # arrange
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'data/dot_net_installer/input.xml'
      t.output = 'somedir/Our.File.Exe'
    end

    # act
    task.exectaskpublic

    # assert
    File.should_not be_exist(@should_deletes[0])
    File.should_not be_exist(@should_deletes[1])
  end

  it 'should remove the temporarily generated manifest XML file' do
    # arrange
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'data/dot_net_installer/input.xml'
      t.output = 'somedir/Our.File.Exe'
      t.manifest = 'data/dot_net_installer/input_manifest.xml'
    end

    # act
    task.exectaskpublic

    # assert
    File.should_not be_exist(@should_deletes[0])
    File.should_not be_exist(@should_deletes[1])
  end

  it 'should leave the temporarily generated XML files around if PRESERVE_TEMP env is set' do
    # arrange
    ENV['PRESERVE_TEMP'] = 'true'
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'data/dot_net_installer/input.xml'
      t.output = 'somedir/Our.File.Exe'
      t.manifest = 'data/dot_net_installer/input_manifest.xml'
    end

    # act
    task.exectaskpublic

    # assert
    File.should be_exist(@should_deletes[0])
    File.should be_exist(@should_deletes[1])
  end

  it 'should remove the temporarily generated XML file even if an error occurs in the executable' do
    # arrange
    task = BradyW::DotNetInstaller.new do |t|
      t.xml_config = 'data/dot_net_installer/input.xml'
      t.output = 'somedir/Our.File.Exe'
      t.manifest = 'data/dot_net_installer/input_manifest.xml'
    end
    task.stub(:shell).and_yield(nil, SimulateProcessFailure.new)

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception "Problem with dotNetInstaller.  Return code 'BW Rake Task Problem'"
    File.should_not be_exist(@should_deletes[0])
    File.should_not be_exist(@should_deletes[1])
  end
end