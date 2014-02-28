require 'spec_helper'

module BradyW
  class BaseTask < Rake::TaskLib
    attr_accessor :dependencies
  end
end

class TestTask < BradyW::BaseTask
  def exectask
    shell 'dependent_task'
  end
end

describe BradyW::WixCoordinator do
  before :each do
    stub_const 'BswTech::DnetInstallUtil::PARAFFIN_EXE', 'path/to/paraffin.exe'
    BswTech::DnetInstallUtil.stub(:dot_net_installer_base_path).and_return('path/to/dnetinstaller')
    @mock_accessor = BradyW::RegistryAccessor.new
    # No dependency injection framework required :)
    BradyW::RegistryAccessor.stub(:new).and_return(@mock_accessor)
  end

  after :each do
    begin
      BradyW::MSBuild.unstub(:new)
    rescue RSpec::Mocks::MockExpectationError
    end
    begin
      BradyW::Paraffin::FragmentUpdater.unstub(:new)
    rescue RSpec::Mocks::MockExpectationError
    end
    begin
      BradyW::DotNetInstaller.unstub(:new)
    rescue RSpec::Mocks::MockExpectationError
    end
    begin
      BradyW::SignTool.unstub(:new)
    rescue RSpec::Mocks::MockExpectationError
    end

    FileUtils.rm_rf 'MyWixProject'
  end

  it 'should declare Paraffin update, MSBuild, DotNetInstaller tasks as dependencies' do
    # arrange + act
    task = BradyW::WixCoordinator.new :coworking_installer do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.installer_referencer_bin = 'somedir'
    end

    # assert
    task.dependencies.should == ["paraffin_#{task.name}",
                                 "wixmsbld_#{task.name}",
                                 "dnetinst_#{task.name}"]
  end

  it 'should require product_version, upgrade_code, wix_project_directory' do
    # arrange
    task = BradyW::WixCoordinator.new

    # act + assert
    lambda {
      task.exectaskpublic
    }.should raise_exception ':product_version, :upgrade_code, :wix_project_directory, and :installer_referencer_bin are all required'
  end

  it 'should work with custom paraffin fragment name, custom output file, and custom dotnet installer xml file' do
    # arrange
    pf_mock = BradyW::Paraffin::FragmentUpdater.new
    BradyW::Paraffin::FragmentUpdater.stub(:new) do |&block|
      block[pf_mock]
      pf_mock
    end
    dnet_mock = BradyW::DotNetInstaller.new
    BradyW::DotNetInstaller.stub(:new) do |&block|
      block[dnet_mock]
      dnet_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.paraffin_update_fragment = 'custom.wxs'
      t.dnetinstaller_output_exe = 'some.exe'
      t.dnetinstaller_xml_config = 'some.xml'
      t.msi_path = 'path/to/msi'
      t.installer_referencer_bin = 'somedir'
    end

    # assert
    pf_mock.fragment_file.should == 'custom.wxs'
    dnet_mock.output.should == 'some.exe'
    dnet_mock.xml_config.should == 'some.xml'
    dnet_mock.tokens.should == {:Configuration => :Release,
                                :ProductVersion => '1.0.0.0',
                                :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                :MsiPath => 'path/to/msi',
                                :MsiFileName => 'msi'}
  end

  it 'should configure the MSBuild task with proper WIX variables when spaces exist in property values' do
    # arrange
    # allow us to create an instance, then mock future creations of that instance while preserving the block
    ms_build_mock = BradyW::MSBuild.new
    BradyW::MSBuild.stub(:new) do |&block|
      block[ms_build_mock]
      ms_build_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.properties = {:setting1 => 'the setting', :setting2 => 'the set ting 2'}
      t.installer_referencer_bin = 'somedir'
    end

    # assert
    expect(ms_build_mock.build_config).to eq(:Release)
    # the space is due to MSBuild task's parameter forming
    ms_build_mock.send(:solution).should == ' MyWixProject/MyWixProject.wixproj'
    ms_build_mock.properties.should == {:setting1 => 'the setting',
                                        :setting2 => 'the set ting 2',
                                        :ProductVersion => '1.0.0.0',
                                        :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                        :DefineConstants => 'ProductVersion=1.0.0.0;UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7;setting1=the setting;setting2=the set ting 2;TRACE'}
  end

  it 'should configure the MSBuild task with proper WIX variables when semicolons exist in property values' do
    # arrange
    # allow us to create an instance, then mock future creations of that instance while preserving the block
    ms_build_mock = BradyW::MSBuild.new
    BradyW::MSBuild.stub(:new) do |&block|
      block[ms_build_mock]
      ms_build_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.properties = {:setting1 => 'the setting', :setting2 => 'the set;ting 2'}
      t.installer_referencer_bin = 'somedir'
    end

    # assert
    expect(ms_build_mock.build_config).to eq(:Release)
    # the space is due to MSBuild task's parameter forming
    ms_build_mock.send(:solution).should == ' MyWixProject/MyWixProject.wixproj'
    ms_build_mock.properties.should == {:setting1 => 'the setting',
                                        :setting2 => 'the set;ting 2',
                                        :ProductVersion => '1.0.0.0',
                                        :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                        :DefineConstants => 'ProductVersion=1.0.0.0;UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7;setting1=the setting;setting2=the set%3Bting 2;TRACE'}
  end

  it 'should work properly with properties without spaces' do
    # arrange
    # allow us to create an instance, then mock future creations of that instance while preserving the block
    ms_build_mock = BradyW::MSBuild.new
    BradyW::MSBuild.stub(:new) do |&block|
      block[ms_build_mock]
      ms_build_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.properties = {:setting1 => 'setting1', :setting2 => 'setting2'}
      t.installer_referencer_bin = 'somedir'
    end

    # assert
    expect(ms_build_mock.build_config).to eq(:Release)
    # the space is due to MSBuild task's parameter forming
    ms_build_mock.send(:solution).should == ' MyWixProject/MyWixProject.wixproj'
    ms_build_mock.properties.should == {:setting1 => 'setting1',
                                        :setting2 => 'setting2',
                                        :ProductVersion => '1.0.0.0',
                                        :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                        :DefineConstants => 'ProductVersion=1.0.0.0;UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7;setting1=setting1;setting2=setting2;TRACE'}
  end

  it 'should configure the MSBuild task' do
    # arrange
    # allow us to create an instance, then mock future creations of that instance while preserving the block
    ms_build_mock = BradyW::MSBuild.new
    BradyW::MSBuild.stub(:new) do |&block|
      block[ms_build_mock]
      ms_build_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.properties = {:setting1 => 'the setting', :setting2 => 'the setting 2'}
      t.installer_referencer_bin = 'somedir'
    end

    # assert
    expect(ms_build_mock.build_config).to eq(:Release)
    # the space is due to MSBuild task's parameter forming
    ms_build_mock.send(:solution).should == ' MyWixProject/MyWixProject.wixproj'
    ms_build_mock.properties.should == {:setting1 => 'the setting',
                                        :setting2 => 'the setting 2',
                                        :ProductVersion => '1.0.0.0',
                                        :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                        :DefineConstants => 'ProductVersion=1.0.0.0;UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7;setting1=the setting;setting2=the setting 2;TRACE'}
  end

  it 'should configure the Paraffin task' do
    # arrange
    pf_mock = BradyW::Paraffin::FragmentUpdater.new
    BradyW::Paraffin::FragmentUpdater.stub(:new) do |&block|
      block[pf_mock]
      pf_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.installer_referencer_bin = 'somedir'
    end

    # assert
    pf_mock.fragment_file.should == 'MyWixProject/paraffin/binaries.wxs'
    pf_mock.output_directory = 'somedir'
  end

  it 'should configure the DotNetInstaller task' do
    # arrange
    dnet_mock = BradyW::DotNetInstaller.new
    BradyW::DotNetInstaller.stub(:new) do |&block|
      block[dnet_mock]
      dnet_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'src/MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.properties = {:setting1 => 'the setting', :setting2 => 'the setting 2'}
      t.installer_referencer_bin = 'somedir'
    end

    # assert
    dnet_mock.tokens.should == {:setting1 => 'the setting',
                                :setting2 => 'the setting 2',
                                :Configuration => :Release,
                                :ProductVersion => '1.0.0.0',
                                :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                :MsiPath => 'src/MyWixProject/bin/Release/MyWixProject.msi',
                                :MsiFileName => 'MyWixProject.msi'}
    dnet_mock.output.should == 'src/MyWixProject/bin/Release/MyWixProject 1.0.0.0.exe'
    dnet_mock.xml_config.should == 'src/MyWixProject/dnetinstaller.xml'
  end

  it 'should configure the DotNetInstaller task with a manifest if specified' do
    # arrange
    dnet_mock = BradyW::DotNetInstaller.new
    BradyW::DotNetInstaller.stub(:new) do |&block|
      block[dnet_mock]
      dnet_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'src/MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.bootstrapper_manifest = 'the/manifest.xml'
      t.installer_referencer_bin = 'somedir'
    end

    # assert
    dnet_mock.output.should == 'src/MyWixProject/bin/Release/MyWixProject 1.0.0.0.exe'
    dnet_mock.xml_config.should == 'src/MyWixProject/dnetinstaller.xml'
    dnet_mock.manifest.should == 'the/manifest.xml'
  end

  it 'should allow Debug to be specified as the config' do
    # arrange
    ms_build_mock = BradyW::MSBuild.new
    BradyW::MSBuild.stub(:new) do |&block|
      block[ms_build_mock]
      ms_build_mock
    end
    dnet_mock = BradyW::DotNetInstaller.new
    BradyW::DotNetInstaller.stub(:new) do |&block|
      block[dnet_mock]
      dnet_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.properties = {:setting1 => 'the setting', :setting2 => 'the setting 2'}
      t.build_config = :Debug
      t.installer_referencer_bin = 'somedir'
    end

    # assert
    dnet_mock.tokens.should == {:setting1 => 'the setting',
                                :setting2 => 'the setting 2',
                                :Configuration => :Debug,
                                :ProductVersion => '1.0.0.0',
                                :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                :MsiPath => 'MyWixProject/bin/Debug/MyWixProject.msi',
                                :MsiFileName => 'MyWixProject.msi'}
    dnet_mock.output.should == 'MyWixProject/bin/Debug/MyWixProject 1.0.0.0.exe'
    ms_build_mock.build_config.should == :Debug
    ms_build_mock.properties.should == {:setting1 => 'the setting',
                                        :setting2 => 'the setting 2',
                                        :ProductVersion => '1.0.0.0',
                                        :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                        :DefineConstants => 'Debug;ProductVersion=1.0.0.0;UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7;setting1=the setting;setting2=the setting 2;DEBUG;TRACE'}
    # DEBUG is needed for preprocessor variables
  end

  it 'allows Debug to be specified as a string, not just a symbol' do
    # arrange
    ms_build_mock = BradyW::MSBuild.new
    BradyW::MSBuild.stub(:new) do |&block|
      block[ms_build_mock]
      ms_build_mock
    end
    dnet_mock = BradyW::DotNetInstaller.new
    BradyW::DotNetInstaller.stub(:new) do |&block|
      block[dnet_mock]
      dnet_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.properties = {:setting1 => 'the setting', :setting2 => 'the setting 2'}
      t.build_config = 'Debug'
      t.installer_referencer_bin = 'somedir'
    end

    # assert
    dnet_mock.tokens.should == {:setting1 => 'the setting',
                                :setting2 => 'the setting 2',
                                :Configuration => :Debug,
                                :ProductVersion => '1.0.0.0',
                                :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                :MsiPath => 'MyWixProject/bin/Debug/MyWixProject.msi',
                                :MsiFileName => 'MyWixProject.msi'}
    dnet_mock.output.should == 'MyWixProject/bin/Debug/MyWixProject 1.0.0.0.exe'
    ms_build_mock.build_config.should == :Debug
    ms_build_mock.properties.should == {:setting1 => 'the setting',
                                        :setting2 => 'the setting 2',
                                        :ProductVersion => '1.0.0.0',
                                        :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                        :DefineConstants => 'Debug;ProductVersion=1.0.0.0;UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7;setting1=the setting;setting2=the setting 2;DEBUG;TRACE'}
    # DEBUG is needed for preprocessor variables
  end

  it 'should allow MSBuild properties like .NET version, etc. to be passed along' do
    # arrange
    ms_build_mock = BradyW::MSBuild.new
    BradyW::MSBuild.stub(:new) do |&block|
      block[ms_build_mock]
      ms_build_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.properties = {:setting1 => 'the setting', :setting2 => 'the setting 2'}
      t.msbuild_configure = lambda { |m| m.dotnet_bin_version = :v4_0 }
      t.installer_referencer_bin = 'somedir'
    end

    # assert
    ms_build_mock.dotnet_bin_version.should == :v4_0
  end

  it 'should not allow the top level release_mode flag to be overridden by properties since we need to interpret the config for defineConstants' do
    # arrange + act

    lambda {
      BradyW::WixCoordinator.new do |t|
        t.product_version = '1.0.0.0'
        t.wix_project_directory = 'MyWixProject'
        t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
        t.properties = {:setting1 => 'the setting', :setting2 => 'the setting 2', :Configuration => :Debug}
        t.msbuild_configure = lambda { |m| m.dotnet_bin_version = :v4_0 }
        t.installer_referencer_bin = 'somedir'
      end

      # assert
    }.should raise_exception "You cannot supply Debug for a :Configuration property.  Use the :build_config property on the WixCoordinator task"
  end

  it 'should work properly with no additional properties supplied' do
    # arrange
    ms_build_mock = BradyW::MSBuild.new
    BradyW::MSBuild.stub(:new) do |&block|
      block[ms_build_mock]
      ms_build_mock
    end
    dnet_mock = BradyW::DotNetInstaller.new
    BradyW::DotNetInstaller.stub(:new) do |&block|
      block[dnet_mock]
      dnet_mock
    end

    # act
    BradyW::WixCoordinator.new do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.installer_referencer_bin = 'somedir'
    end

    # assert
    dnet_mock.tokens.should == {:Configuration => :Release,
                                :ProductVersion => '1.0.0.0',
                                :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                :MsiPath => 'MyWixProject/bin/Release/MyWixProject.msi',
                                :MsiFileName => 'MyWixProject.msi'}
    ms_build_mock.properties.should == {:ProductVersion => '1.0.0.0',
                                        :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                        :DefineConstants => 'ProductVersion=1.0.0.0;UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7;TRACE'}
  end

  it 'executes each dependency it defines' do
    # arrange
    FileUtils.mkdir_p 'MyWixProject/paraffin'
    FileUtils.touch 'MyWixProject/paraffin/binaries.wxs'
    ms_build_mock = BradyW::MSBuild.new :msbuild_task
    BradyW::MSBuild.stub(:new) do |&block|
      block[ms_build_mock]
      ms_build_mock
    end
    task = BradyW::WixCoordinator.new :integration_test do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.properties = {:setting1 => 'the setting', :setting2 => 'the setting 2'}
      t.installer_referencer_bin = 'somedir'
    end
    ms_build_mock.stub(:dotnet).and_return('path/to/')
    FileUtils.touch 'MyWixProject/paraffin/binaries.PARAFFIN'
    FileUtils.touch 'MyWixProject/dnetinstaller.xml'
    commands = []

    # act

    Rake::Task[:integration_test].invoke
    5.times { commands << task.executedPop }

    # assert
    commands[4].should == "cmd.exe /c mklink /J \"MyWixProject\\paraffin\\paraffin_config_aware_symlink\" \"somedir\""
    commands[3].should == '"path/to/paraffin.exe" -update "MyWixProject/paraffin/binaries.wxs" -verbose'
    commands[2].should == "rmdir \"MyWixProject\\paraffin\\paraffin_config_aware_symlink\""
    commands[1].should == 'path/to/msbuild.exe /property:Configuration=Release /property:TargetFrameworkVersion=v4.5 /property:ProductVersion=1.0.0.0 /property:UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7 /property:setting1="the setting" /property:setting2="the setting 2" /property:DefineConstants="ProductVersion=1.0.0.0;UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7;setting1=the setting;setting2=the setting 2;TRACE" MyWixProject/MyWixProject.wixproj'
    commands[0].should include '"path/to/dnetinstaller/Bin/InstallerLinker.exe" /c:"MyWixProject/dnetinstall'
    commands[0].should include '/o:"MyWixProject/bin/Release/MyWixProject 1.0.0.0.exe" /t:"path/to/dnetinstaller/Bin/dotNetInstaller.exe"'
  end

  it 'should execute dependency (singular) of the overall task before the dependencies it defines' do
    # arrange
    FileUtils.mkdir_p 'MyWixProject/paraffin'
    FileUtils.touch 'MyWixProject/paraffin/binaries.wxs'
    ms_build_mock = BradyW::MSBuild.new :msbuild_task_2
    BradyW::MSBuild.stub(:new) do |&block|
      block[ms_build_mock]
      ms_build_mock
    end

    TestTask.new :test_task
    BradyW::WixCoordinator.new :integration_test2 => :test_task do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.properties = {:setting1 => 'the setting', :setting2 => 'the setting 2'}
      t.installer_referencer_bin = 'somedir'
    end
    ms_build_mock.stub(:dotnet).and_return('path/to/')
    FileUtils.touch 'MyWixProject/paraffin/binaries.PARAFFIN'
    FileUtils.touch 'MyWixProject/dnetinstaller.xml'
    commands = []

    # act
    Rake::Task[:integration_test2].invoke
    Rake::Task[:integration_test].invoke
    6.times { commands << BradyW::BaseTask.pop_executed_command }

    # assert
    commands[5].should == 'dependent_task'
    commands[4].should == "cmd.exe /c mklink /J \"MyWixProject\\paraffin\\paraffin_config_aware_symlink\" \"somedir\""
    commands[3].should == '"path/to/paraffin.exe" -update "MyWixProject/paraffin/binaries.wxs" -verbose'
    commands[2].should == "rmdir \"MyWixProject\\paraffin\\paraffin_config_aware_symlink\""
    commands[1].should == 'path/to/msbuild.exe /property:Configuration=Release /property:TargetFrameworkVersion=v4.5 /property:ProductVersion=1.0.0.0 /property:UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7 /property:setting1="the setting" /property:setting2="the setting 2" /property:DefineConstants="ProductVersion=1.0.0.0;UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7;setting1=the setting;setting2=the setting 2;TRACE" MyWixProject/MyWixProject.wixproj'
    commands[0].should include '"path/to/dnetinstaller/Bin/InstallerLinker.exe" /c:"MyWixProject/dnetinstall'
    commands[0].should include '/o:"MyWixProject/bin/Release/MyWixProject 1.0.0.0.exe" /t:"path/to/dnetinstaller/Bin/dotNetInstaller.exe"'
  end

  it 'should execute dependencies (plural) of the overall task before the dependencies it defines' do
    # arrange
    FileUtils.mkdir_p 'MyWixProject/paraffin'
    FileUtils.touch 'MyWixProject/paraffin/binaries.wxs'
    ms_build_mock = BradyW::MSBuild.new :msbuild_task_3
    BradyW::MSBuild.stub(:new) do |&block|
      block[ms_build_mock]
      ms_build_mock
    end

    TestTask.new :test_task_3
    TestTask.new :test_task_4
    BradyW::WixCoordinator.new :integration_test3 => [:test_task_3, :test_task_4] do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.properties = {:setting1 => 'the setting', :setting2 => 'the setting 2'}
      t.installer_referencer_bin = 'somedir'
    end
    ms_build_mock.stub(:dotnet).and_return('path/to/')
    FileUtils.touch 'MyWixProject/paraffin/binaries.PARAFFIN'
    FileUtils.touch 'MyWixProject/dnetinstaller.xml'
    commands = []

    # act
    Rake::Task[:integration_test3].invoke
    7.times { commands << BradyW::BaseTask.pop_executed_command }

    # assert
    commands[6].should == 'dependent_task'
    commands[5].should == 'dependent_task'
    commands[4].should == "cmd.exe /c mklink /J \"MyWixProject\\paraffin\\paraffin_config_aware_symlink\" \"somedir\""
    commands[3].should == '"path/to/paraffin.exe" -update "MyWixProject/paraffin/binaries.wxs" -verbose'
    commands[2].should == "rmdir \"MyWixProject\\paraffin\\paraffin_config_aware_symlink\""
    commands[1].should == 'path/to/msbuild.exe /property:Configuration=Release /property:TargetFrameworkVersion=v4.5 /property:ProductVersion=1.0.0.0 /property:UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7 /property:setting1="the setting" /property:setting2="the setting 2" /property:DefineConstants="ProductVersion=1.0.0.0;UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7;setting1=the setting;setting2=the setting 2;TRACE" MyWixProject/MyWixProject.wixproj'
    commands[0].should include '"path/to/dnetinstaller/Bin/InstallerLinker.exe" /c:"MyWixProject/dnetinstall'
    commands[0].should include '/o:"MyWixProject/bin/Release/MyWixProject 1.0.0.0.exe" /t:"path/to/dnetinstaller/Bin/dotNetInstaller.exe"'
  end

  it "should fail to execute the task when we don't have required parameters" do
    # arrange
    puts "Arranging"
    TestTask.new :test_task_5
    task = BradyW::WixCoordinator.new(:integration_test4 => :test_task_5)

    # assert
    expect(task.dependencies).to be_nil

    # act
    puts 'Acting'
    lambda { Rake::Task[:integration_test4].invoke }.should raise_exception ':product_version, :upgrade_code, :wix_project_directory, and :installer_referencer_bin are all required'
    command1 = BradyW::BaseTask.pop_executed_command

    # assert
    command1.should be_nil
  end

  it 'should optionally perform code signing if description and certificate_subject are provided (and use properties without spaces)' do
    # arrange
    FileUtils.mkdir_p 'MyWixProject/paraffin'
    FileUtils.touch 'MyWixProject/paraffin/binaries.wxs'
    ms_build_mock = BradyW::MSBuild.new :msbuild_task_4
    BradyW::MSBuild.stub(:new) do |&block|
      block[ms_build_mock]
      ms_build_mock
    end
    @mock_accessor.stub(:get_sub_keys).with('SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows').and_return(['v7.1A', 'v8.0A', 'v8.1A', 'v8.1'])
    @mock_accessor.stub(:get_value).with('SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v8.1', 'InstallationFolder').and_return('windowskit/path')

    TestTask.new :test_task_6
    TestTask.new :test_task_7
    BradyW::WixCoordinator.new :integration_test5 => [:test_task_6, :test_task_7] do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.certificate_subject = 'The Subject'
      t.description = 'The description'
      t.installer_referencer_bin = 'somedir'
    end
    ms_build_mock.stub(:dotnet).and_return('path/to/')
    FileUtils.touch 'MyWixProject/paraffin/binaries.PARAFFIN'
    FileUtils.touch 'MyWixProject/dnetinstaller.xml'

    # act
    Rake::Task[:integration_test5].invoke
    commands = 9.times.collect { BradyW::BaseTask.pop_executed_command }
    commands = commands.reverse

    # assert
    commands[0].should == 'dependent_task'
    commands[1].should == 'dependent_task'
    commands[2].should == "cmd.exe /c mklink /J \"MyWixProject\\paraffin\\paraffin_config_aware_symlink\" \"somedir\""
    commands[3].should == '"path/to/paraffin.exe" -update "MyWixProject/paraffin/binaries.wxs" -verbose'
    commands[4].should == "rmdir \"MyWixProject\\paraffin\\paraffin_config_aware_symlink\""
    commands[5].should == 'path/to/msbuild.exe /property:Configuration=Release /property:TargetFrameworkVersion=v4.5 /property:ProductVersion=1.0.0.0 /property:UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7 /property:DefineConstants="ProductVersion=1.0.0.0;UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7;TRACE" MyWixProject/MyWixProject.wixproj'
    commands[6].should == '"windowskit/path/bin/x64/signtool.exe" sign /n "The Subject" /t http://timestamp.verisign.com/scripts/timestamp.dll /d "The description" "MyWixProject/bin/Release/MyWixProject.msi"'
    commands[7].should include '"path/to/dnetinstaller/Bin/InstallerLinker.exe" /c:"MyWixProject/dnetinstall'
    commands[7].should include '/o:"MyWixProject/bin/Release/MyWixProject 1.0.0.0.exe" /t:"path/to/dnetinstaller/Bin/dotNetInstaller.exe"'
    commands[8].should == '"windowskit/path/bin/x64/signtool.exe" sign /n "The Subject" /t http://timestamp.verisign.com/scripts/timestamp.dll /d "The description" "MyWixProject/bin/Release/MyWixProject 1.0.0.0.exe"'
  end

  it 'should allow executing the Paraffin task on its own (without a version number)' do
    # arrange
    FileUtils.mkdir_p 'MyWixProject/paraffin'
    FileUtils.touch 'MyWixProject/paraffin/binaries.wxs'
    BradyW::WixCoordinator.new :integration_test6 do |t|
      t.wix_project_directory = 'MyWixProject'
      t.installer_referencer_bin = 'somedir'
    end
    FileUtils.touch 'MyWixProject/paraffin/binaries.PARAFFIN'
    FileUtils.touch 'MyWixProject/dnetinstaller.xml'

    # act
    Rake::Task[:paraffin_integration_test6].invoke
    commands = 3.times.collect { BradyW::BaseTask.pop_executed_command }
    commands = commands.reverse

    # assert
    commands[0].should == "cmd.exe /c mklink /J \"MyWixProject\\paraffin\\paraffin_config_aware_symlink\" \"somedir\""
    commands[1].should == '"path/to/paraffin.exe" -update "MyWixProject/paraffin/binaries.wxs" -verbose'
    commands[2].should == "rmdir \"MyWixProject\\paraffin\\paraffin_config_aware_symlink\""
  end

  it 'should allow a custom timestamp URL' do
    # arrange
    FileUtils.mkdir_p 'MyWixProject/paraffin'
    FileUtils.touch 'MyWixProject/paraffin/binaries.wxs'
    ms_build_mock = BradyW::MSBuild.new :msbuild_task_5
    BradyW::MSBuild.stub(:new) do |&block|
      block[ms_build_mock]
      ms_build_mock
    end
    @mock_accessor.stub(:get_sub_keys).with('SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows').and_return(['v7.1A', 'v8.0A', 'v8.1A', 'v8.1'])
    @mock_accessor.stub(:get_value).with('SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v8.1', 'InstallationFolder').and_return('windowskit/path')

    TestTask.new :test_task_8
    TestTask.new :test_task_9
    BradyW::WixCoordinator.new :integration_test7 => [:test_task_8, :test_task_9] do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
      t.certificate_subject = 'The Subject'
      t.description = 'The description'
      t.code_sign_timestamp_server = 'http://something.else'
      t.installer_referencer_bin = 'somedir'
    end
    ms_build_mock.stub(:dotnet).and_return('path/to/')
    FileUtils.touch 'MyWixProject/paraffin/binaries.PARAFFIN'
    FileUtils.touch 'MyWixProject/dnetinstaller.xml'

    # act
    Rake::Task[:integration_test7].invoke
    commands = 7.times.collect { BradyW::BaseTask.pop_executed_command }
    commands = commands.reverse

    # assert
    commands[4].should == '"windowskit/path/bin/x64/signtool.exe" sign /n "The Subject" /t http://something.else /d "The description" "MyWixProject/bin/Release/MyWixProject.msi"'
    commands[6].should == '"windowskit/path/bin/x64/signtool.exe" sign /n "The Subject" /t http://something.else /d "The description" "MyWixProject/bin/Release/MyWixProject 1.0.0.0.exe"'
  end
end