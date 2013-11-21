require 'base'
require 'basetaskmocking'
require 'paraffin_runner'

describe BradyW::ParaffinRunner do
  before(:each) do
    @mockBasePath = 'someParaffinPath\Paraffin.exe'
    stub_const 'BswTech::DnetInstallUtil::PARAFFIN_EXE', @mockBasePath
  end

  it 'should work properly when specifying dir ref' do
    # arrange
    task = BradyW::ParaffinRunner.new do |t|
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
    fail 'Write this test'
  end

  it 'should require a component group, alias, output file, and directory to scan' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end

  it 'should use -NoRootDirectory' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end

  it 'should generate a WXS with 1 extension ignored, 1 directory excluded, 1 regex excluded' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end

  it 'should generate a WXS with 2 extensions ignored, 2 directories excluded, 2 regexes excluded' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end

  it 'should allow a custom path' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end
end