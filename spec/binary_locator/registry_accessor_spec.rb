require 'spec_helper'

describe BradyW::RegistryAccessor, :if => ENV['windows_test'] do
  it 'should work OK with a 64 bit registry call' do
    # arrange
    accessor = BradyW::RegistryAccessor.new

    # act
    value = accessor.get_value 'SOFTWARE\\7-Zip', 'Path'

    # assert
    expect(value).to eq('C:\\Program Files\\7-Zip\\')
  end

  it 'should use standard 32 bit registry mode if 64 fails' do
    # arrange
    accessor = BradyW::RegistryAccessor.new

    # act
    value = accessor.get_value 'SOFTWARE\\JetBrains\\ReSharper\\v8.0', 'CompanyName'

    # assert
    expect(value).to eq('JetBrains')
  end

  it 'should fail if it doesnt exist' do
    # partial mocking is done with this
    accessor = BradyW::RegistryAccessor.new
    lambda { accessor.get_value('SOFTWARE\\foobar', 'regvalue') }.should raise_exception("Unable to find registry key: SOFTWARE\\foobar")
  end

  it 'should retrieve registry keys properly' do
    # arrange
    accessor = BradyW::RegistryAccessor.new

    # act
    keys = accessor.get_sub_keys('SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows')

    # assert
    expect(keys).to eq(['v7.1A', 'v8.0A', 'v8.1A', 'v8.1'])
  end
end