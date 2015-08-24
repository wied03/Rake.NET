RSpec.shared_context :config_helper do
  before do
    @config = BradyW::BaseConfig.new
    class MockConfig
      include Singleton
      attr_accessor :values
    end
    # Force only our base class to be returned
    allow(BradyW::Config).to receive(:instance).and_return(MockConfig.instance)
    MockConfig.instance.values = @config
  end
end
