require "base"
require "bcp"
require "basetaskmisc"
require 'ftools'

describe "BCP Data Loading" do
  before(:each) do
    # This resets our recorded output
    sh2 "---new test---"
    @props = {}
    BW::Config.stub!(:Props).and_return(@props)
    @basepath = File.expand_path(File.dirname(__FILE__))
    @props["db"] = {"name" => "regulardb"}
    @props["db"]["hostname"] = "myhostname"
    @props['db']["use"] = {"mode" => "sqlauth",
                           "user" => "theuser",
                           "password" => "thepassword"}
    @props["project"] = {"prefix" => "PRE"}
  end

  after(:each) do
    # Remove our generated test data
    FileUtils::rm_rf File.expand_path(File.dirname(__FILE__))+"/data/output/bcp"
  end

  it "Works OK with standard delimiters and SQL Auth" do
    @task = BW::BCP.new do |bcp|
      bcp.files = FileList[@basepath+"/data/bcp/*-tablecase1.csv"]      
    end

    # Don't want to depend on specific registry setting
    @task.should_receive(:sql_tool).any_number_of_times.with("100").and_return("z:\\")

    @task.exectaskpublic
    @task.sh.should == "\"z:\\bcp.exe\" \"tablecase1\" in 02-tablecase1.csv -U theuser -P thepassword /Smyhostname -t \"|d3l1m1t3r|\" /c -m 1 -F 2"
    @task.sh.should == "\"z:\\bcp.exe\" \"tablecase1\" in 01-tablecase1.csv -U theuser -P thepassword /Smyhostname -t \"|d3l1m1t3r|\" /c -m 1 -F 2"

    File.compare (@basepath+"/data/bcp/01-tablecase1-expectedout.csv",
                  @basepath+"/data/output/bcp/01-tablecase1.csv").should == true

    File.compare (@basepath+"/data/bcp/02-tablecase1-expectedout.csv",
                  @basepath+"/data/output/bcp/02-tablecase1.csv").should == true
  end

  it "Works OK with custom delimiters, Custom Version, and Windows Auth" do
    @props['db']["use"] = {"mode" => "winauth"}
    @task = BW::BCP.new do |bcp|
      bcp.files = FileList[@basepath+"/data/bcp/*-tablecase1.csv"]
      bcp.delimiter = "foobar"
      bcp.version = "852"
    end

    # Don't want to depend on specific registry setting
    @task.should_receive(:sql_tool).any_number_of_times.with("852").and_return("z:\\")

    @task.exectaskpublic
    @task.sh.should == "\"z:\\bcp.exe\" \"regulardb.dbo.tablecase1\" in 02-tablecase1.csv -T -S myhostname -t \"foobar\" /c -m 1 -F 2"
    @task.sh.should == "\"z:\\bcp.exe\" \"regulardb.dbo.tablecase1\" in 01-tablecase1.csv -T -S myhostname -t \"foobar\" /c -m 1 -F 2"

    File.compare (@basepath+"/data/bcp/01-tablecase1-expectedout2.csv",
                  @basepath+"/data/output/bcp/01-tablecase1.csv").should == true

    File.compare (@basepath+"/data/bcp/02-tablecase1-expectedout2.csv",
                  @basepath+"/data/output/bcp/02-tablecase1.csv").should == true
  end

  it "Handles delimiter interference Properly" do
    @props['db']["use"] = {"mode" => "winauth"}
    @task = BW::BCP.new do |bcp|
      bcp.files = FileList[@basepath+"/data/bcp/delimInData.csv"]
    end

    lambda {@task.exectaskpublic}.should raise_exception()     
  end

end