require "base"
require "registry_accessor"

describe BradyW::RegistryAccessor do
  before(:each) do
    # partial mocking is done with this
    @windowPathsWrapper = BradyW::RegistryAccessor.new
  end

  it "should work OK with a 64 bit registry call" do
    @windowPathsWrapper.should_receive(:regvalue64).any_number_of_times.with("regkey",
                                                            "regvalue").and_return("hi")
    @windowPathsWrapper.stub!(:regvalue32).and_return("not me")
    result = @windowPathsWrapper.regvalue "regkey", "regvalue"
    result.should == "hi"
  end

  it "should use standard 32 bit registry mode if 64 fails" do
     @windowPathsWrapper.stub!(:regvalue64).and_raise("Registry failure")
     @windowPathsWrapper.should_receive(:regvalue32).any_number_of_times.with("regkey",
                                                             "regvalue").and_return("hi")
     result = @windowPathsWrapper.regvalue "regkey", "regvalue"
     result.should == "hi"
  end

  it "should fail if the 32 bit call fails after trying 64" do
     @windowPathsWrapper.stub!(:regvalue64).and_raise("Registry failure")
     @windowPathsWrapper.stub!(:regvalue32).and_raise("Registry failure")
     lambda {@windowPathsWrapper.regvalue("regkey", "regvalue")}.should raise_exception("Unable to find registry value in either 32 or 64 bit mode: regkey\\regvalue")
  end
end