require 'spec_helper'

describe BradyW::WindowsPaths do
  before do
    @mock_accessor = instance_double BradyW::RegistryAccessor
    allow(BradyW::RegistryAccessor).to receive(:new).and_return(@mock_accessor)
  end

  let(:wrapper_class) do
    Class.new do
      include BradyW::WindowsPaths

      public :sql_tool, :visual_studio, :dotnet

      def log text
        puts text
      end
    end
  end

  subject(:wrapper) { wrapper_class.new }

  describe '#sql_tool' do
    before do
      allow(@mock_accessor).to receive(:get_value).with('SOFTWARE\\Microsoft\\Microsoft SQL Server\\verhere\\Tools\\ClientSetup', 'Path').and_return 'howdy'
    end

    subject { wrapper.sql_tool 'verhere' }

    it { is_expected.to eq 'howdy' }
  end

  describe '#visual_studio' do
    before do
      allow(@mock_accessor).to receive(:get_value).with('SOFTWARE\\Microsoft\\VisualStudio\\verhere', 'InstallDir').and_return 'howdy'
    end

    subject { wrapper.visual_studio 'verhere' }

    it { is_expected.to eq 'howdy' }
  end

  describe '#dotnet' do
    before do
      allow(@mock_accessor).to receive(:get_value).with('SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\verhere', 'InstallPath').and_return 'howdy'
    end

    subject { wrapper.dotnet 'verhere' }

    it { is_expected.to eq 'howdy' }
  end
end
