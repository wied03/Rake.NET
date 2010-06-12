require "base"
require "bcp"
require "basetaskmisc"

describe "BCP Data Loading" do
  before(:each) do
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
    task = BW::BCP.new do |bcp|
      bcp.files = FileList[@basepath+"/data/bcp/01-firsttable.csv",
                           @basepath+"/data/bcp/02-nexttable.csv"]      
    end

    # Don't want to depend on specific registry setting
    task.should_receive(:sql_tool).any_number_of_times.with("100").and_return("z:\\")

    task.exectaskpublic
    task.excecutedPop.should == "\"z:\\bcp.exe\" \"nexttable\" in 02-nexttable.csv -U theuser -P thepassword /Smyhostname -t \"|d3l1m1t3r|\" /c -m 1 -F 2"
    task.excecutedPop.should == "\"z:\\bcp.exe\" \"firsttable\" in 01-firsttable.csv -U theuser -P thepassword /Smyhostname -t \"|d3l1m1t3r|\" /c -m 1 -F 2"

    expected = IO.readlines(@basepath+"/data/bcp/01-firsttable-expectedout.csv")
    actual = IO.readlines(@basepath+"/data/output/bcp/01-firsttable.csv")

    actual.should == expected

    expected = IO.readlines(@basepath+"/data/bcp/02-nexttable-expectedout.csv")
    actual = IO.readlines(@basepath+"/data/output/bcp/02-nexttable.csv")

    actual.should == expected

  end

  it "Works OK with custom delimiters, Custom Version, and Windows Auth" do
    @props['db']["use"] = {"mode" => "winauth"}
    task = BW::BCP.new do |bcp|
      bcp.files = FileList[@basepath+"/data/bcp/01-firsttable.csv",
                           @basepath+"/data/bcp/02-nexttable.csv"]
      bcp.delimiter = "foobar"
      bcp.version = "852"
    end

    # Don't want to depend on specific registry setting
    task.should_receive(:sql_tool).any_number_of_times.with("852").and_return("z:\\")

    task.exectaskpublic
    task.excecutedPop.should == "\"z:\\bcp.exe\" \"regulardb.dbo.nexttable\" in 02-nexttable.csv -T -S myhostname -t \"foobar\" /c -m 1 -F 2"
    task.excecutedPop.should == "\"z:\\bcp.exe\" \"regulardb.dbo.firsttable\" in 01-firsttable.csv -T -S myhostname -t \"foobar\" /c -m 1 -F 2"

    expected = IO.readlines(@basepath+"/data/bcp/01-firsttable-expectedout2.csv")
    actual = IO.readlines(@basepath+"/data/output/bcp/01-firsttable.csv")

    actual.should == expected

    expected = IO.readlines(@basepath+"/data/bcp/02-nexttable-expectedout2.csv")
    actual = IO.readlines(@basepath+"/data/output/bcp/02-nexttable.csv")

    actual.should == expected
  end

  it "Handles delimiter interference Properly" do
    @props['db']["use"] = {"mode" => "winauth"}
    task = BW::BCP.new do |bcp|
      bcp.files = FileList[@basepath+"/data/bcp/delimInData.csv"]
    end

    lambda {task.exectaskpublic}.should raise_exception()     
  end

end