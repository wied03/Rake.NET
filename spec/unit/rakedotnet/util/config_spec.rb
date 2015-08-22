require 'spec_helper'

describe BradyW::Config do
  before(:all) do
    $: << "#{File.expand_path(File.dirname(__FILE__))}/config_testdata"
  end

  after(:each) do
    File.delete 'newuserfile.rb' if File.exist? 'newuserfile.rb'
  end

  def fetchprops(defaultfile,userfile)
    # get around the private method
    BradyW::Config.send(:new,defaultfile,userfile).values
  end

  it 'Should work fine with only default properties' do
    props = fetchprops('onlydefault.rb',
                       'newuserfile.rb')

    props.setting.should == 'yep'
    props.setting2.should == 'nope'
    props.setting3.should == 'yep'
  end

  it 'Should work OK with default + partially filled out user properties' do
    props = fetchprops('defaultpartialuser_default.rb',
                       'defaultpartialuser_user.rb')

    props.setting.should == 'overrodethis'
    props.setting2.should == 'nope'
    props.setting3.should == 'yep'
  end

  it 'Should work OK with default + completely filled out user properties' do
    props = BradyW::Config.send(:new).values

    props.setting.should == 'yep2'
    props.setting2.should == 'nope2'
    props.setting3.should == 'yep2'
  end
end