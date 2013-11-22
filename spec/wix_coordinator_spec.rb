require 'base'
require 'wix_coordinator'
require 'basetaskmocking'

module BradyW
  class BaseTask < Rake::TaskLib
    attr_accessor :dependencies
  end
end

describe BradyW::WixCoordinator do
  it 'should declare a Paraffin update, MSBuild, and DotNetInstaller task as dependencies' do
    # arrange + act
    task = BradyW::WixCoordinator.new :coworking_installer do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.paraffin_update_fragment = 'someDir/someFile.wxs'
      t.dnetinstaller_xml_config = 'someDir/dnetinstall.xml'
      t.dnetinstaller_output_exe = 'someDir/output.exe'
    end

    # assert
    task.dependencies.should == ["paraffin_#{task.name}",
                                 "wixmsbld_#{task.name}",
                                 "dnetinst_#{task.name}"]
  end

  it 'should require product_version, upgrade_code, wix_project_directory, Paraffin update fragment, xml config for dot net installer, and output exe file' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end

  it 'should configure the MSBuild task' do
    # arrange
    # allow us to create an instance, then mock future creations of that instance while preserving the block
    ms_build_mock = BradyW::MSBuild.new
    BradyW::MSBuild.stub!(:new) do |&block|
      # we should be supply a release config option in a block
      block[ms_build_mock]
      ms_build_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.paraffin_update_fragment = 'someDir/someFile.wxs'
      t.dnetinstaller_xml_config = 'someDir/dnetinstall.xml'
      t.dnetinstaller_output_exe = 'someDir/output.exe'
      t.properties = {:setting1 => 'the setting', :setting2 => 'the setting 2'}
    end

    # assert
    ms_build_mock.release.should be_true
    # the space is due to MSBuild task's parameter forming
    ms_build_mock.send(:solution).should == ' MyWixProject'
    ms_build_mock.properties.should == {:setting1 => 'the setting', :setting2 => 'the setting 2'}
  end

  it 'should configure the Paraffin task' do
    # arrange
    pf_mock = BradyW::Paraffin::FragmentUpdater.new
    BradyW::Paraffin::FragmentUpdater.stub!(:new) do |&block|
      block[pf_mock]
      pf_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.paraffin_update_fragment = 'someDir/someFile.wxs'
      t.dnetinstaller_xml_config = 'someDir/dnetinstall.xml'
      t.dnetinstaller_output_exe = 'someDir/output.exe'
    end

    # assert
    pf_mock.fragment_file.should == 'someDir/someFile.wxs'
  end

  it 'should configure the DotNetInstaller task' do
    # arrange
    dnet_mock = BradyW::DotNetInstaller.new
    BradyW::DotNetInstaller.stub!(:new) do |&block|
      block[dnet_mock]
      dnet_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.paraffin_update_fragment = 'someDir/someFile.wxs'
      t.dnetinstaller_xml_config = 'someDir/dnetinstall.xml'
      t.dnetinstaller_output_exe = 'someDir/output.exe'
      t.properties = {:setting1 => 'the setting', :setting2 => 'the setting 2'}
    end

    # assert
    dnet_mock.tokens.should == {:setting1 => 'the setting', :setting2 => 'the setting 2', :Configuration => :Release}
    dnet_mock.output.should == 'someDir/output.exe'
    dnet_mock.xml_config.should == 'someDir/dnetinstall.xml'
  end

  it 'should allow Debug to be specified as the config' do
    # arrange
    ms_build_mock = BradyW::MSBuild.new
    BradyW::MSBuild.stub!(:new) do |&block|
      # we should be supply a release config option in a block
      block[ms_build_mock]
      ms_build_mock
    end
    dnet_mock = BradyW::DotNetInstaller.new
    BradyW::DotNetInstaller.stub!(:new) do |&block|
      block[dnet_mock]
      dnet_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.paraffin_update_fragment = 'someDir/someFile.wxs'
      t.dnetinstaller_xml_config = 'someDir/dnetinstall.xml'
      t.dnetinstaller_output_exe = 'someDir/output.exe'
      t.properties = {:setting1 => 'the setting', :setting2 => 'the setting 2'}
      t.release_mode = false
    end

    # assert
    dnet_mock.tokens.should == {:setting1 => 'the setting', :setting2 => 'the setting 2', :Configuration => :Debug}
    ms_build_mock.release.should be_false
  end

  it 'should allow MSBuild properties like .NET version, etc. to be passed along' do
    # arrange

    # act

    # assert
    fail 'Write this test'
  end

  it 'should not allow the top level release_mode flag to be overriden by properties' do
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