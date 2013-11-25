require "base"
require "bcp"
require "basetaskmocking"

describe BradyW::BCP do
  before(:each) do
    def @config.db_name
      "regulardb"
    end

    def @config.db_hostname
      "myhostname"
    end

    def @config.db_general_authmode
      :sqlauth
    end

    def @config.db_general_user
      "theuser"
    end

    def @config.db_general_password
      "thepassword"
    end

    def @config.project_prefix
      "PRE"
    end
  end

  after(:each) do
    # Remove our generated test data
    FileUtils::rm_rf "data/output/bcp"
  end

  it "Works OK with standard delimiters and SQL Auth" do
    task = BradyW::BCP.new do |bcp|
      bcp.files = FileList["data/bcp/01-firsttable.csv",
                           "data/bcp/02-nexttable.csv"]
    end

    # Don't want to depend on specific registry setting
    task.stub(:sql_tool).with("100").and_return("z:\\")

    task.exectaskpublic
    task.executedPop.should == "\"z:\\bcp.exe\" \"nexttable\" in 02-nexttable.csv -U theuser -P thepassword /Smyhostname -t \"|d3l1m1t3r|\" /c -m 1 -F 2"
    task.executedPop.should == "\"z:\\bcp.exe\" \"firsttable\" in 01-firsttable.csv -U theuser -P thepassword /Smyhostname -t \"|d3l1m1t3r|\" /c -m 1 -F 2"

    expected = IO.readlines("data/bcp/01-firsttable-expectedout.csv")
    actual = IO.readlines("data/output/bcp/01-firsttable.csv")

    actual.should == expected

    expected = IO.readlines("data/bcp/02-nexttable-expectedout.csv")
    actual = IO.readlines("data/output/bcp/02-nexttable.csv")

    actual.should == expected

  end

  it "Works OK with custom delimiters, Custom Version, and Windows Auth" do
    def @config.db_general_authmode
      :winauth
    end

    task = BradyW::BCP.new do |bcp|
      bcp.files = FileList["data/bcp/01-firsttable.csv",
                           "data/bcp/02-nexttable.csv"]
      bcp.delimiter = "foobar"
      bcp.version = "852"
    end

    # Don't want to depend on specific registry setting
    task.stub(:sql_tool).with("852").and_return("z:\\")

    task.exectaskpublic
    task.executedPop.should == "\"z:\\bcp.exe\" \"regulardb.dbo.nexttable\" in 02-nexttable.csv -T -S myhostname -t \"foobar\" /c -m 1 -F 2"
    task.executedPop.should == "\"z:\\bcp.exe\" \"regulardb.dbo.firsttable\" in 01-firsttable.csv -T -S myhostname -t \"foobar\" /c -m 1 -F 2"

    expected = IO.readlines("data/bcp/01-firsttable-expectedout2.csv")
    actual = IO.readlines("data/output/bcp/01-firsttable.csv")

    actual.should == expected

    expected = IO.readlines("data/bcp/02-nexttable-expectedout2.csv")
    actual = IO.readlines("data/output/bcp/02-nexttable.csv")

    actual.should == expected
  end

  it "Handles delimiter interference Properly" do
    def @config.db_general_authmode
          :winauth
        end

    task = BradyW::BCP.new do |bcp|
      bcp.files = FileList["data/bcp/delimInData.csv"]
    end

    lambda { task.exectaskpublic }.should raise_exception()
  end

  it "Handles failure gracefully" do
    task = BradyW::BCP.new do |bcp|
      bcp.files = FileList["data/bcp/01-firsttable.csv",
                           "data/bcp/02-nexttable.csv"]
    end

    # Don't want to depend on specific registry setting
    task.should_receive(:sql_tool).with("100").and_return("z:\\")

    task.stub(:shell).and_yield(nil, SimulateProcessFailure.new)

    lambda { task.exectaskpublic }.should raise_exception("Command failed with status (BW Rake Task Problem):")

    # This means our temporary file was correctly cleaned up
    File.exist?("#{ENV['tmp']}/bcp").should_not == true
    # Our test code should have done this
    File.exist?("data/output/bcp").should == true
  end

  it "Properly disables identity inserts when set" do
    task = BradyW::BCP.new do |bcp|
      bcp.identity_inserts = true
      bcp.files = FileList["data/bcp/01-firsttable.csv",
                           "data/bcp/02-nexttable.csv"]
    end
    # Don't want to depend on specific registry setting
    task.stub(:sql_tool).with("100").and_return("z:\\")

    task.exectaskpublic
    task.executedPop.should == "\"z:\\bcp.exe\" \"nexttable\" in 02-nexttable.csv -U theuser -P thepassword /Smyhostname -t \"|d3l1m1t3r|\" /c -E -m 1 -F 2"
    task.executedPop.should == "\"z:\\bcp.exe\" \"firsttable\" in 01-firsttable.csv -U theuser -P thepassword /Smyhostname -t \"|d3l1m1t3r|\" /c -E -m 1 -F 2"

  end
end