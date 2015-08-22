require 'spec_helper'

RSpec.shared_context :msbuild_helpers do
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
end
