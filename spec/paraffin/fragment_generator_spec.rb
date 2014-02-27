require 'base'
require 'paraffin/fragment_generator'
require 'basetaskmocking'

describe BradyW::Paraffin::FragmentGenerator do
  before(:each) do
    @mockBasePath = 'someParaffinPath\Paraffin.exe'
    stub_const 'BswTech::DnetInstallUtil::PARAFFIN_EXE', @mockBasePath
  end

  it 'should work properly when specifying dir ref' do
    # arrange
    task = BradyW::Paraffin::FragmentGenerator.new do |t|
      t.directory_reference = 'BinDir'
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\Bin\Release'
    end

    # act
    task.exectaskpublic
    command3 = task.executedPop
    command2 = task.executedPop
    command1 = task.executedPop

    # assert
    command1.should eq 'cmd.exe /c mklink /J ".\paraffin_config_aware_symlink" "..\Bin\Release"'
    command2.should eq '"someParaffinPath\Paraffin.exe" -dir ".\paraffin_config_aware_symlink" -dr BinDir -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -verbose'
    command3.should eq 'rmdir ".\paraffin_config_aware_symlink"'
  end

  it 'should require a component group, alias, output file, and directory to scan' do
    # arrange
    task = BradyW::Paraffin::FragmentGenerator.new

    # act + assert
    lambda { task.exectaskpublic }.should raise_exception "These required attributes must be set by your task: [:component_group, :alias, :output_file, :directory_to_scan]"
  end

  it 'should use -NoRootDirectory' do
    # arrange
    task = BradyW::Paraffin::FragmentGenerator.new do |t|
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'otherdir/something.wxs'
      t.directory_to_scan = '..\Bin\Release'
      t.no_root_directory = true
    end

    # act
    task.exectaskpublic
    command3 = task.executedPop
    command2 = task.executedPop
    command1 = task.executedPop

    # assert
    command1.should eq 'cmd.exe /c mklink /J "otherdir\paraffin_config_aware_symlink" "..\Bin\Release"'
    command2.should eq '"someParaffinPath\Paraffin.exe" -dir "otherdir\paraffin_config_aware_symlink" -GroupName ServiceBinariesGroup otherdir/something.wxs -alias $(var.Project.TargetDir) -verbose -NoRootDirectory'
    command3.should eq 'rmdir "otherdir\paraffin_config_aware_symlink"'
  end

  it 'should generate a WXS with 1 extension ignored, 1 directory excluded, 1 regex excluded' do
    # arrange
    task = BradyW::Paraffin::FragmentGenerator.new do |t|
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\Bin\Release'
      t.no_root_directory = false
      t.ignore_extensions = 'pdb'
      t.exclude_regexp = '.*'
    end

    # act
    task.exectaskpublic
    command3 = task.executedPop
    command2 = task.executedPop
    command1 = task.executedPop

    # assert
    command1.should eq 'cmd.exe /c mklink /J ".\paraffin_config_aware_symlink" "..\Bin\Release"'
    command2.should eq '"someParaffinPath\Paraffin.exe" -dir ".\paraffin_config_aware_symlink" -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -ext pdb -regExExclude ".*" -verbose'
    command3.should eq 'rmdir ".\paraffin_config_aware_symlink"'
  end

  it 'should generate a WXS with 2 extensions ignored, 2 directories excluded, 2 regexes excluded' do
    # arrange
    task = BradyW::Paraffin::FragmentGenerator.new do |t|
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\Bin\Release'
      t.no_root_directory = false
      t.ignore_extensions = ['pdb', 'txt']
      t.exclude_regexp = ['\d+', '\w+']
    end

    # act
    task.exectaskpublic
    command3 = task.executedPop
    command2 = task.executedPop
    command1 = task.executedPop

    # assert
    command1.should eq 'cmd.exe /c mklink /J ".\paraffin_config_aware_symlink" "..\Bin\Release"'
    command2.should eq '"someParaffinPath\Paraffin.exe" -dir ".\paraffin_config_aware_symlink" -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -ext pdb -ext txt -regExExclude "\d+" -regExExclude "\w+" -verbose'
    command3.should eq 'rmdir ".\paraffin_config_aware_symlink"'
  end

  it 'should generate a WXS with 1 absolute directory ignored via regex' do
    # arrange
    task = BradyW::Paraffin::FragmentGenerator.new do |t|
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\Bin\Release'
      t.directories_to_exclude = 'C:/somefile'
    end

    # act
    task.exectaskpublic
    task.executedPop
    command = task.executedPop

    # assert
    command.should eq '"someParaffinPath\Paraffin.exe" -dir ".\paraffin_config_aware_symlink" -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -regExExclude "C:\\somefile" -verbose'

    fail 'Write this test'
  end

  it 'should generate a WXS with 1 relative directory ignored via regex' do
    # arrange
    task = BradyW::Paraffin::FragmentGenerator.new do |t|
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\Bin\Release'
      t.directories_to_exclude = 'somedir'
    end

    # act
    task.exectaskpublic
    task.executedPop
    command = task.executedPop

    # assert
    command.should eq '"someParaffinPath\Paraffin.exe" -dir ".\paraffin_config_aware_symlink" -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -regExExclude "\.\\paraffin_config_aware_symlink\\somedir" -verbose'

    fail 'Write this test'
  end

  it 'should generate a WXS with 2 absolute directories ignored via regex' do
    # arrange
    task = BradyW::Paraffin::FragmentGenerator.new do |t|
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\Bin\Release'
      t.directories_to_exclude = 'C:/somefile', 'c:\someotherdir'
    end

    # act
    task.exectaskpublic
    task.executedPop
    command = task.executedPop

    # assert
    command.should eq '"someParaffinPath\Paraffin.exe" -dir ".\paraffin_config_aware_symlink" -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -regExExclude "C:\\somefile" -regExExclude "C:\\someotherdir" -verbose'

    fail 'Write this test'
  end

  it 'should generate a WXS with 2 relative directories ignored via regex' do
    # arrange
    task = BradyW::Paraffin::FragmentGenerator.new do |t|
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\Bin\Release'
      t.directories_to_exclude = 'somedir', 'otherdir'
    end

    # act
    task.exectaskpublic
    task.executedPop
    command = task.executedPop

    # assert
    command.should eq '"someParaffinPath\Paraffin.exe" -dir ".\paraffin_config_aware_symlink" -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -regExExclude "\.\\paraffin_config_aware_symlink\\somedir" -regExExclude "\.\\paraffin_config_aware_symlink\\otherdir" -verbose'

    fail 'Write this test'
  end

  it 'should generate a WXS with 1 relative and 1 absolute directory ignored via regex' do
    # arrange
    task = BradyW::Paraffin::FragmentGenerator.new do |t|
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\Bin\Release'
      t.directories_to_exclude = 'somedir', 'c:\someotherdir'
    end

    # act
    task.exectaskpublic
    task.executedPop
    command = task.executedPop

    # assert
    command.should eq '"someParaffinPath\Paraffin.exe" -dir ".\paraffin_config_aware_symlink" -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -regExExclude "\.\\paraffin_config_aware_symlink\\somedir" -regExExclude "C:\\someotherdir" -verbose'

    fail 'Write this test'
  end

  it 'should generate a WXS with a mixture of directories and expressions via regex' do
    # arrange
    task = BradyW::Paraffin::FragmentGenerator.new do |t|
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\Bin\Release'
      t.directories_to_exclude = 'somedir'
      t.exclude_regexp = ['\d+', '\w+']
    end

    # act
    task.exectaskpublic
    task.executedPop
    command = task.executedPop

    # assert
    command.should eq '"someParaffinPath\Paraffin.exe" -dir ".\paraffin_config_aware_symlink" -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -regExExclude "\.\\paraffin_config_aware_symlink\\somedir" -regExExclude "\d+" -regExEclude "\w+" -verbose'

    fail 'Write this test'
  end

  it 'should cleanup symlinks even if Paraffin fails' do
    # arrange
    task = BradyW::Paraffin::FragmentGenerator.new do |t|
      t.directory_reference = 'BinDir'
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\Bin\Release'
    end
    @commands = []
    task.stub(:shell) { |*commands, &block|
      puts commands
      @commands << commands
      raise 'Paraffin failed' if commands[0].include?('Paraffin.exe')
    }

    # act
    lambda { task.exectaskpublic }.should raise_exception "Paraffin failed"

    # assert
    @commands[0][0].should == 'cmd.exe /c mklink /J ".\paraffin_config_aware_symlink" "..\Bin\Release"'
    @commands[1][0].should == '"someParaffinPath\Paraffin.exe" -dir ".\paraffin_config_aware_symlink" -dr BinDir -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -verbose'
    @commands[2][0].should == 'rmdir ".\paraffin_config_aware_symlink"'
  end


  it 'should properly replace regex directories, etc.' do
    # arrange

    # TODO: This basic idea works, but need to 1) adapt tests to cmd.exe reality, 2) confirm the rmdir stuff works and 3) Figure out what to do about arguments like the regex ones that include the directory we are scanning

    # act

    # assert
    fail 'Write this test'
  end
end