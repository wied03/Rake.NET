require 'spec_helper'
require_relative 'msbuild_helpers'

describe BradyW::MSBuild do
  include_context :executable_test
  include_context :msbuild_helpers

  context 'default task settings' do
    context 'latest MSB version is only version' do
      let(:msb_paths) { {'14.0' => 'C:\\Program Files (x86)\\MSBuild\\14.0\\bin\\'} }

      it { is_expected.to execute_bin eq '"C:\\Program Files (x86)\\MSBuild\\14.0\\bin\\MSBuild.exe"' }
      it { is_expected.to execute_with_params eq '/property:Configuration=Debug' }
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

      it { is_expected.to execute_bin eq '"C:\\Program Files (x86)\\MSBuild\\14.0\\bin\\MSBuild.exe"' }
      it { is_expected.to execute_with_params eq '/property:Configuration=Debug' }
    end
  end

  context 'specific MSB version' do
    let(:task_block) { lambda { |t| t.path = msb_version } }

    context 'float' do
      context 'no spaces in path' do
        let(:msb_version) { 3.5 }

        it { is_expected.to execute_bin eq 'C:\\Windows\\Microsoft.NET\\Framework\\v3.5\\MSBuild.exe' }
      end

      context 'valid' do
        let(:msb_version) { 12.0 }

        it { is_expected.to execute_bin eq '"C:\\Program Files (x86)\\MSBuild\\12.0\\bin\\MSBuild.exe"' }
      end

      context 'version not installed' do
        let(:msb_version) { 22.2 }

        subject { lambda { task } }

        it { is_expected.to raise_exception 'You requested version 22.2 but that version is not installed. Installed versions are [14.0, 12.0, 4.0, 3.5, 2.0]' }
      end
    end

    context 'integer' do
      let(:msb_version) { 12 }

      it { is_expected.to execute_bin eq '"C:\\Program Files (x86)\\MSBuild\\12.0\\bin\\MSBuild.exe"' }
    end

    context 'string' do
      context 'file path' do
        let(:msb_version) { 'C:\\some_path\\MSBuild.exe' }

        context 'valid' do
          before do
            allow(File).to receive(:exist?).with('C:\\some_path\\MSBuild.exe').and_return true
          end

          it { is_expected.to execute_bin eq 'C:\\some_path\\MSBuild.exe' }
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
          let(:msb_version) { '12.0' }

          it { is_expected.to execute_bin eq '"C:\\Program Files (x86)\\MSBuild\\12.0\\bin\\MSBuild.exe"' }
        end

        context 'invalid' do
          let(:msb_version) { '22.2' }

          subject { lambda { task } }

          it { is_expected.to raise_exception 'You requested version 22.2 but that version is not installed. Installed versions are [14.0, 12.0, 4.0, 3.5, 2.0]' }
        end
      end
    end
  end

  context 'properties' do
    let(:task_block) { lambda { |t| t.properties = build_props } }

    context 'value includes spaces' do
      let(:build_props) { {:prop1 => 'the value'} }

      it { is_expected.to execute_with_params eq '/property:Configuration=Debug /property:prop1="the value"' }
    end

    context 'value includes semicolons' do
      let(:build_props) { {:prop1 => 'the;value'} }

      it { is_expected.to execute_with_params eq '/property:Configuration=Debug /property:prop1="the;value"' }
    end

    context 'custom properties that are also defaults' do
      let(:build_props) {
        {
            Configuration: 'myconfig',
            prop2: 'prop2val'
        }
      }

      it { is_expected.to execute_with_params eq '/property:Configuration=myconfig /property:prop2=prop2val' }
    end
  end

  context 'explicit solution' do
    let(:task_block) { lambda { |t| t.solution = 'junk.sln' } }

    it { is_expected.to execute_with_params eq '/property:Configuration=Debug junk.sln' }
  end

  context 'target(s)' do
    let(:task_block) { lambda { |t| t.targets = build_targets } }

    context 'single' do
      let(:build_targets) { 't1' }

      it { is_expected.to execute_with_params eq '/target:t1 /property:Configuration=Debug' }
    end

    context 'multiple' do
      let(:build_targets) { %w{t1 t2} }

      it { is_expected.to execute_with_params eq '/target:t1 /target:t2 /property:Configuration=Debug' }
    end
  end

  context 'build config' do
    let(:task_block) { lambda { |t| t.build_config = build_config } }

    context 'explicit debug' do
      let(:build_config) { :Debug }

      it { is_expected.to execute_with_params eq '/property:Configuration=Debug' }
    end

    context 'release' do
      let(:build_config) { :Release }

      it { is_expected.to execute_with_params eq '/property:Configuration=Release' }
    end
  end

  context 'explicit compile version' do
    let(:task_block) { lambda { |t| t.compile_version = compile_version } }

    context 'integer' do
      let(:compile_version) { 4 }

      it { is_expected.to execute_with_params eq '/property:Configuration=Debug /property:TargetFrameworkVersion=v4.0' }
    end

    context 'float' do
      let(:compile_version) { 4.0 }

      it { is_expected.to execute_with_params eq '/property:Configuration=Debug /property:TargetFrameworkVersion=v4.0' }
    end

    context 'string' do
      context 'valid' do
        let(:compile_version) { '4.0' }

        it { is_expected.to execute_with_params eq '/property:Configuration=Debug /property:TargetFrameworkVersion=v4.0' }
      end

      context 'invalid' do
        let(:compile_version) { 'foobar' }

        subject { lambda { task } }

        it { is_expected.to raise_exception "Compile version needs to be convertible to float and 'foobar' is not" }
      end
    end
  end
end
