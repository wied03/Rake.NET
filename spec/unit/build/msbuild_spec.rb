require 'spec_helper'

describe BradyW::MSBuild do
  let(:task_block) { lambda { |t|} }
  subject(:task) { BradyW::MSBuild.new(&task_block) }
  let(:msb_paths) do
    {
        '12.0' => 'C:\\Program Files (x86)\\MSBuild\\12.0\\bin\\',
        '14.0' => 'C:\\Program Files (x86)\\MSBuild\\14.0\\bin\\',
        '2.0' => 'C:\\Windows\\Microsoft.NET\\Framework\\v2.0.50727\\',
        '3.5' => 'C:\\Windows\\Microsoft.NET\\Framework\\v3.5\\',
        '4.0' => 'C:\\Windows\\Microsoft.NET\\Framework\\v4.0.30319\\'
    }
  end

  before do
    @mock_accessor = instance_double BradyW::RegistryAccessor
    allow(BradyW::RegistryAccessor).to receive(:new).and_return(@mock_accessor)
    allow(@mock_accessor).to receive(:get_sub_keys).with('SOFTWARE\\Microsoft\\MSBuild\\ToolsVersions').and_return msb_paths.keys
    msb_paths.each do |version, path|
      allow(@mock_accessor).to receive(:get_value).with("SOFTWARE\\Microsoft\\MSBuild\\ToolsVersions\\#{version}", 'MsBuildToolsPath').and_return path
    end
  end

  RSpec::Matchers.define :execute_commands do |matcher|
    def actual(task)
      task.exectaskpublic
      task.executedPop
    end

    match do |task|
      matcher.matches?(actual(task))
    end

    failure_message do
      matcher.failure_message
    end
  end

  context 'default task settings' do
    context 'latest MSB version is only version' do
      let(:msb_paths) { {'14.0' => 'C:\\Program Files (x86)\\MSBuild\\14.0\\bin\\'} }

      it { is_expected.to execute_commands eq '"C:\\Program Files (x86)\\MSBuild\\14.0\\bin\\MSBuild.exe" /property:Configuration=Debug /property:TargetFrameworkVersion=v4.5' }
    end

    context 'multiple MSB versions' do
      let(:msb_paths) do
        {
            '12.0' => 'C:\\Program Files (x86)\\MSBuild\\12.0\\bin\\',
            '14.0' => 'C:\\Program Files (x86)\\MSBuild\\14.0\\bin\\',
            '2.0' => 'C:\\Windows\\Microsoft.NET\\Framework\\v2.0.50727\\',
            '3.5' => 'C:\\Windows\\Microsoft.NET\\Framework\\v3.5\\',
            '4.0' => 'C:\\Windows\\Microsoft.NET\\Framework\\v4.0.30319\\'
        }
      end

      it { is_expected.to execute_commands eq '"C:\\Program Files (x86)\\MSBuild\\14.0\\bin\\MSBuild.exe" /property:Configuration=Debug /property:TargetFrameworkVersion=v4.5' }
    end

  end

  context 'specific MSB version' do
    context 'float' do
      context 'no spaces in path' do
        let(:task_block) { lambda { |t| t.path = 3.5 } }

        it { is_expected.to execute_commands eq 'C:\\Windows\\Microsoft.NET\\Framework\\v3.5\\MSBuild.exe /property:Configuration=Debug /property:TargetFrameworkVersion=v4.5' }
      end

      context 'valid' do
        let(:task_block) { lambda { |t| t.path = 12.0 } }

        it { is_expected.to execute_commands eq '"C:\\Program Files (x86)\\MSBuild\\12.0\\bin\\MSBuild.exe" /property:Configuration=Debug /property:TargetFrameworkVersion=v4.5' }
      end

      context 'version not installed' do
        let(:task_block) { lambda { |t| t.path = 22.2 } }

        subject { lambda { task } }

        it { is_expected.to raise_exception 'You requested version 22.2 but that version is not installed. Installed versions are [14.0, 12.0, 4.0, 3.5, 2.0]' }
      end
    end

    context 'integer' do
      let(:task_block) { lambda { |t| t.path = 12 } }

      it { is_expected.to execute_commands eq '"C:\\Program Files (x86)\\MSBuild\\12.0\\bin\\MSBuild.exe" /property:Configuration=Debug /property:TargetFrameworkVersion=v4.5' }
    end

    context 'string' do
      context 'file path' do
        let(:task_block) { lambda { |t| t.path = 'C:\\some_path\\MSBuild.exe' } }

        context 'valid' do
          before do
            allow(File).to receive(:exist?).with('C:\\some_path\\MSBuild.exe').and_return true
          end

          it { is_expected.to execute_commands eq 'C:\\some_path\\MSBuild.exe /property:Configuration=Debug /property:TargetFrameworkVersion=v4.5' }
        end

        context 'invalid' do
          before do
            allow(File).to receive(:exist?).with('C:\\some_path\\MSBuild.exe').and_return false
          end

          subject { lambda { task } }

          it { is_expected.to raise_exception 'You requested to use C:\\some_path\\MSBuild.exe but that file does not exist!' }
        end
      end

      context 'number as string' do
        context 'valid' do
          let(:task_block) { lambda { |t| t.path = '12.0' } }

          it { is_expected.to execute_commands eq '"C:\\Program Files (x86)\\MSBuild\\12.0\\bin\\MSBuild.exe" /property:Configuration=Debug /property:TargetFrameworkVersion=v4.5' }
        end

        context 'invalid' do
          let(:task_block) { lambda { |t| t.path = '22.2' } }

          subject { lambda { task } }

          it { is_expected.to raise_exception 'You requested version 22.2 but that version is not installed. Installed versions are [14.0, 12.0, 4.0, 3.5, 2.0]' }
        end
      end
    end
  end

  context 'properties' do
    context 'value includes spaces' do
      let(:task_block) { lambda { |t| t.properties = {:prop1 => 'the value'} } }

      it { is_expected.to execute_commands eq '"C:\\Program Files (x86)\\MSBuild\\14.0\\bin\\MSBuild.exe" /property:Configuration=Debug /property:TargetFrameworkVersion=v4.5 /property:prop1="the value"' }
    end

    context 'value includes semicolons' do
      let(:task_block) { lambda { |t| t.properties = {:prop1 => 'the;value'} } }

      it { is_expected.to execute_commands eq '"C:\\Program Files (x86)\\MSBuild\\14.0\\bin\\MSBuild.exe" /property:Configuration=Debug /property:TargetFrameworkVersion=v4.5 /property:prop1="the;value"' }
    end

    context 'custom properties that are also defaults' do
      let(:task_block) do
        lambda do |t|
          t.properties = {
              Configuration: 'myconfig',
              prop2: 'prop2val'
          }
          t.build_config = :Release
        end
      end

      it { is_expected.to execute_commands eq '"C:\\Program Files (x86)\\MSBuild\\14.0\\bin\\MSBuild.exe" /property:Configuration=myconfig /property:TargetFrameworkVersion=v4.5 /property:prop2=prop2val' }
    end
  end

  context 'explicit solution' do
    pending 'write this'
  end

  context 'target' do
    pending 'write this'
  end

  context 'build config' do
    context 'explicit debug' do
      let(:task_block) { lambda { |t| t.build_config = :Debug } }

      it { is_expected.to execute_commands eq '"C:\\Program Files (x86)\\MSBuild\\14.0\\bin\\MSBuild.exe" /property:Configuration=Debug /property:TargetFrameworkVersion=v4.5' }
    end

    context 'release' do
      let(:task_block) { lambda { |t| t.build_config = :Release } }

      it { is_expected.to execute_commands eq '"C:\\Program Files (x86)\\MSBuild\\14.0\\bin\\MSBuild.exe" /property:Configuration=Release /property:TargetFrameworkVersion=v4.5' }
    end
  end

  xit 'should build OK (.NET 4.0)' do
    task = BradyW::MSBuild.new do |t|
      t.dotnet_bin_version = :v4_0
      t.compile_version = :v4_0
    end
    expect(task).to receive(:dotnet).with("v4\\Client").and_return("C:\\yespath\\")
    task.exectaskpublic
    execed = task.executedPop
    execed.should == 'C:\\yespath\\msbuild.exe /property:Configuration=Debug /property:TargetFrameworkVersion=v4.0'
  end

  xit 'should build OK with a single target' do
    # arrange
    task = BradyW::MSBuild.new do |t|
      t.targets = 't1'
    end
    expect(task).to receive(:dotnet).with("v4\\Client").and_return("C:\\yespath\\")

    # act
    task.exectaskpublic
    execed = task.executedPop

    # assert
    execed.should == 'C:\\yespath\\msbuild.exe /target:t1 /property:Configuration=Debug /property:TargetFrameworkVersion=v4.5'
  end

  xit 'should build OK with everything customized (.NET 3.5)' do
    # arrange
    task = BradyW::MSBuild.new do |t|
      t.targets = %w(t1 t2)
      t.dotnet_bin_version = :v3_5
      t.solution = 'solutionhere'
      t.compile_version = :v3_5
      t.properties = {'prop1' => 'prop1val',
                      'prop2' => 'prop2val'}
      t.build_config = :Release
    end
    expect(task).to receive(:dotnet).with('v3.5').and_return("C:\\yespath2\\")

    # act
    task.exectaskpublic
    execed = task.executedPop

    # assert
    execed.should == 'C:\\yespath2\\msbuild.exe /target:t1 /target:t2 /property:Configuration=Release /property:TargetFrameworkVersion=v3.5 /property:prop1=prop1val /property:prop2=prop2val solutionhere'
  end
end
