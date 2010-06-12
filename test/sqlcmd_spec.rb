require "base"
require "sqlcmd"
require "basetaskmisc"

module BW
  class Sqlcmd < BaseTask
    # It uses the current date, which is harder to test
    def tempfile
      "tempfile.sql"
    end
  end
end

describe "SQLCMD Testing" do
  before(:each) do
    @props = {}
    BW::Config.stub!(:Props).and_return(@props)
    @db = BW::DB.new
    @props["db"] = {"name" => "regulardb",
                    "hostname" => "myhostname"}
    @props["project"] = {"prefix" => "PRE"}
    @props['db']["use"] = {"mode" => "sqlauth",
                           "user" => "theuser",
                           "password" => "thepassword",
                           "data-dir" => "F:\\"}
  end

  after(:each) do
    # Remove our generated test data
    FileUtils::rm_rf File.expand_path(File.dirname(__FILE__))+"/data/output/raketask_rollup.sql"
  end

  it "Should work with default version and default (non create) credentials in SQL auth mode" do
    @task = BW::Sqlcmd.new do |sql|
      sql.files = FileList["data/sqlcmd/input/**/*"]       
    end

    @task.should_receive(:sql_tool).any_number_of_times.with("100").and_return("z:\\")
    
    @task.exectaskpublic
    @task.sh.should == "\"z:\\sqlcmd.exe\" -U theuser -P thepassword -S myhostname -e -v "+
            "sqlserverdatadirectory=\"F:\\\" dbname=regulardb dbpassword=thepassword dbuser=theuser "+
            "-i tempfile.sql"
    

    # todo, verify we created a temporary SQL file that runs all queries and that it matches expected
    false.should == true
  end

  it "Should work with a custom version and default (non create) credentials in Win auth mode" do
    @props['db']["use"] = {"mode" => "winauth"}

    @task = BW::Sqlcmd.new do |sql|
      sql.files = FileList["data/sqlcmd/input/**/*"]
      sql.version = "902"
    end

    @task.should_receive(:sql_tool).any_number_of_times.with("902").and_return("z:\\")

    @task.exectaskpublic
    @task.sh.should == "\"z:\\sqlcmd.exe\" -E -S myhostname -e -v "+
            "sqlserverdatadirectory=\"F:\\\" dbname=regulardb dbpassword=thepassword dbuser=theuser "+
            "-i tempfile.sql"

     # todo, verify we created a temporary SQL file that runs all queries and that it matches expected
     # todo, verify that we properly execute a different script for this (for different grants, etc.)
    
     false.should == true
  end

  it "Works fine with create credentials in SQL auth mode" do
    @props['db']["create"] = {"mode" => "sqlauth",
                              "user" => "createuser",
                              "password" => "createpassword"}

    @task = BW::Sqlcmd.new do |sql|
      sql.files = FileList["data/sqlcmd/input/**/*"]
      sql.usecreatecredentials = true
    end

    @task.should_receive(:sql_tool).any_number_of_times.with("100").and_return("z:\\")

    @task.exectaskpublic
    @task.sh.should == "\"z:\\sqlcmd.exe\" -U createuser -P createpassword -S myhostname -e -v "+
            "sqlserverdatadirectory=\"F:\\\" dbname=regulardb dbpassword=thepassword dbuser=theuser "+
            "-i tempfile.sql"

    # todo, verify we created a temporary SQL file that runs all queries and that it matches expected
     false.should == true
  end

  it "Works fine with create credentials in Win auth mode" do
    @props['db']["create"] = {"mode" => "winauth"}

    @task = BW::Sqlcmd.new do |sql|
      sql.files = FileList["data/sqlcmd/input/**/*"]
      sql.usecreatecredentials = true
    end

    @task.should_receive(:sql_tool).any_number_of_times.with("100").and_return("z:\\")

    @task.exectaskpublic
    @task.sh.should == "\"z:\\sqlcmd.exe\" -E -S myhostname -e -v "+
            "sqlserverdatadirectory=\"F:\\\" dbname=regulardb dbpassword=thepassword dbuser=theuser "+
            "-i tempfile.sql"

     # todo, verify we created a temporary SQL file that runs all queries and that it matches expected
    
     false.should == true
  end

  it "Works fine with additional variables" do
     false.should == true
  end

  it "Fails the build properly (and gracefully) if sqlcmd has an error" do
    false.should == true
  end
end