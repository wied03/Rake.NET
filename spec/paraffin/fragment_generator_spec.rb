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
    command = task.executedPop

    # assert
    command.should eq '"someParaffinPath\Paraffin.exe" -dir "..\Bin\Release" -dr BinDir -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -verbose'
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
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\Bin\Release'
      t.no_root_directory = true
    end

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    command.should eq '"someParaffinPath\Paraffin.exe" -dir "..\Bin\Release" -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -verbose -NoRootDirectory'
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
    command = task.executedPop

    # assert
    command.should eq '"someParaffinPath\Paraffin.exe" -dir "..\Bin\Release" -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -ext pdb -regExExclude ".*" -verbose'
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
    command = task.executedPop

    # assert
    command.should eq '"someParaffinPath\Paraffin.exe" -dir "..\Bin\Release" -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -ext pdb -ext txt -regExExclude "\d+" -regExExclude "\w+" -verbose'
  end
end