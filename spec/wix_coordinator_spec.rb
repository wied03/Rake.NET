require 'base'
require 'wix_coordinator'
require 'basetaskmocking'

describe BradyW::WixCoordinator do
  it 'should declare a Paraffin update, MSBuild, and DotNetInstaller task as dependencies' do
    # arrange + act
    task = BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.paraffin_update_fragment = 'someDir/someFile.wxs'
      t.dnetinstaller_xml_config = 'someDir/dnetinstall.xml'
      t.dnetinstaller_output_exe = 'someDir/output.exe'
    end

    # assert
    task.dependencies.should == ["paraffin_#{task.name}",
                                 "wixmsbuild_#{task.name}",
                                 "dnetinst_#{task.name}"]
  end

  it 'should require product_version, upgrade_code, Paraffin update fragment, xml config for dot net installer, and output exe file' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end

  it 'should have Release as the default config' do
    # arrange
    ms_build_mock = BradyW::MSBuild.new
    BradyW::MSBuild.stub!(:new) do |task_name,&block|
      puts "Stub reached for newly created MSBuild task #{task_name}"
      # we should be supply a release config option in a block
      block[ms_build_mock]
      ms_build_mock
    end

    # act
    task = BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.paraffin_update_fragment = 'someDir/someFile.wxs'
      t.dnetinstaller_xml_config = 'someDir/dnetinstall.xml'
      t.dnetinstaller_output_exe = 'someDir/output.exe'
    end

    # assert
    ms_build_mock.release.should be_true

    fail 'Write this test'
  end

  it 'should allow Debug to be specified as the config' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end

  it 'should allow MSBuild properties like .NET version, etc. to be passed along' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end

  it 'execute each dependency' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end
end