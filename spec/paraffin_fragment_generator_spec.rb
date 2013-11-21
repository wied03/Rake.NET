require 'base'
require 'paraffin_fragment_generator'
require 'basetaskmocking'

describe BradyW::ParaffinFragmentGenerator do
  before(:each) do
    @mockBasePath = 'someParaffinPath\Paraffin.exe'
    stub_const 'BswTech::DnetInstallUtil::PARAFFIN_EXE', @mockBasePath
  end

  it 'should work properly when specifying dir ref' do
    # arrange
    task = BradyW::ParaffinFragmentGenerator.new do |t|
      t.directory_reference = 'BinDir'
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\bin\Release'
    end

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    expect(command).to eq('"someParaffinPath\Paraffin.exe" -dir "..\Bin\Release" -dr BinDir -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -verbose')
  end

  it 'should require a component group, alias, output file, and directory to scan' do
    # arrange

    # act + assert
    lambda { BradyW::ParaffinFragmentGenerator.new }.should throw "component_group, alias, output_file, directory_to_scan all required"
  end

  it 'should use -NoRootDirectory' do
    # arrange
    task = BradyW::ParaffinFragmentGenerator.new do |t|
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\bin\Release'
      t.no_root_directory = true
    end

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    command.should equal('"someParaffinPath\Paraffin.exe" -dir "..\Bin\Release" -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -verbose -NoRootDirectory')
  end

  it 'should generate a WXS with 1 extension ignored, 1 directory excluded, 1 regex excluded' do
    # arrange
    task = BradyW::ParaffinFragmentGenerator.new do |t|
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\bin\Release'
      t.no_root_directory = false
      t.ignore_extensions = 'pdb'
      t.ignore_directories = 'bin'
      t.exclude_regexp = '.*'
    end

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    command.should equal('"someParaffinPath\Paraffin.exe" -dir "..\Bin\Release" -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -ext pdb -direXclude "bin" -regExExclude ".*" -verbose')
  end

  it 'should generate a WXS with 2 extensions ignored, 2 directories excluded, 2 regexes excluded' do
    # arrange
    task = BradyW::ParaffinFragmentGenerator.new do |t|
      t.component_group = 'ServiceBinariesGroup'
      t.alias = '$(var.Project.TargetDir)'
      t.output_file = 'something.wxs'
      t.directory_to_scan = '..\bin\Release'
      t.no_root_directory = false
      t.ignore_extensions = ['pdb', 'txt']
      t.ignore_directories = ['bin', 'conf']
      t.exclude_regexp = ['\d+', '\w+']
    end

    # act
    task.exectaskpublic
    command = task.executedPop

    # assert
    command.should equal('"someParaffinPath\Paraffin.exe" -dir "..\Bin\Release" -GroupName ServiceBinariesGroup something.wxs -alias $(var.Project.TargetDir) -ext pdb -ext txt -direXclude "bin" -direXclude "conf" -regExExclude "\d+" -regExExclude "\w+" -verbose')
    fail 'Write this test'
  end
end