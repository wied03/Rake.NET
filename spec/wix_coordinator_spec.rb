require 'base'
require 'wix_coordinator'
require 'basetaskmocking'

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

    FileUtils.rm_rf 'MyWixProject'
  end

  it 'should declare a Paraffin update, MSBuild, and DotNetInstaller task as dependencies' do
    # arrange + act
    task = BradyW::WixCoordinator.new :coworking_installer do |t|
      t.product_version = '1.0.0.0'
      t.wix_project_directory = 'MyWixProject'
      t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
    end

    # assert
    task.dependencies.should == ["paraffin_#{task.name}",
                                 "wixmsbld_#{task.name}",
                                 "dnetinst_#{task.name}"]
  end

  it 'should require product_version, upgrade_code, wix_project_directory' do
    # act + assert
    lambda {
      BradyW::WixCoordinator.new do |w|

      end
    }.should raise_exception ':product_version, :upgrade_code, :wix_project_directory are all required'
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
    end

    # assert
    pf_mock.fragment_file.should == 'custom.wxs'
    dnet_mock.output.should == 'some.exe'
    dnet_mock.xml_config.should == 'some.xml'
    dnet_mock.tokens.should == {:Configuration => :Release,
                                :ProductVersion => '1.0.0.0',
                                :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                :MsiPath => 'path/to/msi'}
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
    end

    # assert
    ms_build_mock.release.should be_true
    # the space is due to MSBuild task's parameter forming
    ms_build_mock.send(:solution).should == ' MyWixProject/MyWixProject.wixproj'
    ms_build_mock.properties.should == {:setting1 => 'the setting',
                                        :setting2 => 'the setting 2',
                                        :ProductVersion => '1.0.0.0',
                                        :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'}
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
    end

    # assert
    pf_mock.fragment_file.should == 'MyWixProject/paraffin/binaries.wxs'
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
    end

    # assert
    dnet_mock.tokens.should == {:setting1 => 'the setting',
                                :setting2 => 'the setting 2',
                                :Configuration => :Release,
                                :ProductVersion => '1.0.0.0',
                                :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                :MsiPath => 'src/MyWixProject/bin/Release/MyWixProject.msi'}
    dnet_mock.output.should == 'src/MyWixProject/bin/Release/MyWixProject 1.0.0.0 Installer.exe'
    dnet_mock.xml_config.should == 'src/MyWixProject/dnetinstaller.xml'
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
      t.release_mode = false
    end

    # assert
    dnet_mock.tokens.should == {:setting1 => 'the setting',
                                :setting2 => 'the setting 2',
                                :Configuration => :Debug,
                                :ProductVersion => '1.0.0.0',
                                :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                :MsiPath => 'MyWixProject/bin/Debug/MyWixProject.msi'}
    dnet_mock.output.should == 'MyWixProject/bin/Debug/MyWixProject 1.0.0.0 Installer.exe'
    ms_build_mock.release.should be_false
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
    end

    # assert
    ms_build_mock.dotnet_bin_version.should == :v4_0
  end

  it 'should not allow the top level release_mode flag to be overridden by properties' do
    # arrange + act

    lambda {
      BradyW::WixCoordinator.new do |t|
        t.product_version = '1.0.0.0'
        t.wix_project_directory = 'MyWixProject'
        t.upgrade_code = '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'
        t.properties = {:setting1 => 'the setting', :setting2 => 'the setting 2', :Configuration => :Debug}
        t.msbuild_configure = lambda { |m| m.dotnet_bin_version = :v4_0 }
      end

      # assert
    }.should raise_exception "You cannot supply Debug for a :Configuration property.  Use the :release_mode property on the WixCoordinator task"
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
    end

    # assert
    dnet_mock.tokens.should == {:Configuration => :Release,
                                :ProductVersion => '1.0.0.0',
                                :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7',
                                :MsiPath => 'MyWixProject/bin/Release/MyWixProject.msi'}
    ms_build_mock.properties.should == {:ProductVersion => '1.0.0.0',
                                        :UpgradeCode => '6c6bbe03-e405-4e6e-84ac-c5ef16f243e7'}
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
    end
    ms_build_mock.stub(:dotnet).and_return('path/to/')
    FileUtils.touch 'MyWixProject/paraffin/binaries.PARAFFIN'
    FileUtils.touch 'MyWixProject/dnetinstaller.xml'

    # act

    Rake::Task[:integration_test].invoke
    command3 = task.executedPop
    command2 = task.executedPop
    command1 = task.executedPop

    # assert
    command1.should == '"path/to/paraffin.exe" -update "MyWixProject/paraffin/binaries.wxs" -verbose'
    command2.should == 'path/to/msbuild.exe /property:Configuration=Release /property:TargetFrameworkVersion=v4.5 /property:ProductVersion=1.0.0.0 /property:UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7 /property:setting1="the setting" /property:setting2="the setting 2" MyWixProject/MyWixProject.wixproj'
    command3.should include '"path/to/dnetinstaller/Bin/InstallerLinker.exe" /c:"MyWixProject/dnetinstall'
    command3.should include '/o:"MyWixProject/bin/Release/MyWixProject 1.0.0.0 Installer.exe" /t:"path/to/dnetinstaller/Bin/dotNetInstaller.exe"'
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
    end
    ms_build_mock.stub(:dotnet).and_return('path/to/')
    FileUtils.touch 'MyWixProject/paraffin/binaries.PARAFFIN'
    FileUtils.touch 'MyWixProject/dnetinstaller.xml'

    # act
    Rake::Task[:integration_test2].invoke
    command4 = BradyW::BaseTask.pop_executed_command
    command3 = BradyW::BaseTask.pop_executed_command
    command2 = BradyW::BaseTask.pop_executed_command
    command1 = BradyW::BaseTask.pop_executed_command

    # assert
    command1.should == 'dependent_task'
    command2.should == '"path/to/paraffin.exe" -update "MyWixProject/paraffin/binaries.wxs" -verbose'
    command3.should == 'path/to/msbuild.exe /property:Configuration=Release /property:TargetFrameworkVersion=v4.5 /property:ProductVersion=1.0.0.0 /property:UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7 /property:setting1="the setting" /property:setting2="the setting 2" MyWixProject/MyWixProject.wixproj'
    command4.should include '"path/to/dnetinstaller/Bin/InstallerLinker.exe" /c:"MyWixProject/dnetinstall'
    command4.should include '/o:"MyWixProject/bin/Release/MyWixProject 1.0.0.0 Installer.exe" /t:"path/to/dnetinstaller/Bin/dotNetInstaller.exe"'
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
    end
    ms_build_mock.stub(:dotnet).and_return('path/to/')
    FileUtils.touch 'MyWixProject/paraffin/binaries.PARAFFIN'
    FileUtils.touch 'MyWixProject/dnetinstaller.xml'

    # act
    Rake::Task[:integration_test3].invoke
    command5 = BradyW::BaseTask.pop_executed_command
    command4 = BradyW::BaseTask.pop_executed_command
    command3 = BradyW::BaseTask.pop_executed_command
    command2 = BradyW::BaseTask.pop_executed_command
    command1 = BradyW::BaseTask.pop_executed_command

    # assert
    command1.should == 'dependent_task'
    command2.should == 'dependent_task'
    command3.should == '"path/to/paraffin.exe" -update "MyWixProject/paraffin/binaries.wxs" -verbose'
    command4.should == 'path/to/msbuild.exe /property:Configuration=Release /property:TargetFrameworkVersion=v4.5 /property:ProductVersion=1.0.0.0 /property:UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7 /property:setting1="the setting" /property:setting2="the setting 2" MyWixProject/MyWixProject.wixproj'
    command5.should include '"path/to/dnetinstaller/Bin/InstallerLinker.exe" /c:"MyWixProject/dnetinstall'
    command5.should include '/o:"MyWixProject/bin/Release/MyWixProject 1.0.0.0 Installer.exe" /t:"path/to/dnetinstaller/Bin/dotNetInstaller.exe"'
  end
end