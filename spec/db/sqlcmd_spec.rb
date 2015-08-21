require 'spec_helper'
require 'rspec/expectations'

def testdata
  FileList["data/sqlcmd/input/**/*"]
end

describe BradyW::Sqlcmd do
  matcher :have_sql_property do |expected|
    match do |actual|
      match = actual.match(/.*-v (.+) -/)
      group = match[1]
      actualProps = group.scan(/('.*?'|\S+=".*?"|\S+)/).map do |kv|
        arr = kv[0].split('=')
        {:k => arr[0], :v => arr[1]}
      end
      actualProps.include? expected
    end
  end

  matcher :have_sql_property_count do |expected|
    match do |actual|
      actualProps = actual.match(/.*-v (.+) -/)[1].scan(/('.*?'|\S+=".*?"|\S+)/)
      actualProps.length == expected
    end
  end

  before(:each) do
    # It uses the current date, which is harder to test
    BradyW::Sqlcmd.stub(:generatetempfilename).and_return "tempfile.sql"
  end

  before(:each) do
    @db = BradyW::Database.new

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

    def @config.db_system_authmode
      :sqlauth
    end

    def @config.db_system_user
      "systemuser"
    end

    def @config.db_system_password
      "systempassword"
    end

    def @config.db_system_datadir
      "F:\\"
    end

    def @config.db_objectcreation_authmode
      :sqlauth
    end

    def @config.db_objectcreation_user
      "objectcreateuser"
    end

    def @config.db_objectcreation_password
      "objectcreatepassword"
    end
  end

  after(:each) do
    # Remove our generated test data
    FileUtils::rm_rf "data/output/tempfile.sql"
    FileUtils::rm_rf "data/output/makedynamic"
  end

  it "Should work with default version and default (non create) credentials in SQL auth mode" do
    task = BradyW::Sqlcmd.new do |sql|
      sql.files = testdata
    end

    task.should_receive(:sql_tool).with("100").and_return("z:\\")

    task.exectaskpublic
    execed = task.executedPop
    execed.should match(/"z:\\sqlcmd\.exe" -U theuser -P thepassword -S myhostname -e -b -v .* -i tempfile.sql/)

    expect(execed).to have_sql_property ({:k => "dbname", :v => "regulardb"})
    execed.should have_sql_property ({:k => "dbuser", :v => "theuser"})
    execed.should have_sql_property_count 2

    expected = IO.readlines("data/sqlcmd/expected.sql")
    actual = IO.readlines("data/output/tempfile.sql")

    actual.should == expected
  end

  it "Should work with a custom version and default (non create) credentials in Win auth mode" do
    def @config.db_general_authmode
      :winauth
    end

    task = BradyW::Sqlcmd.new do |sql|
      sql.files = testdata
      sql.version = "902"
    end

    task.should_receive(:sql_tool).with("902").and_return("z:\\")

    task.exectaskpublic

    execed = task.executedPop
    execed.should match(/"z:\\sqlcmd\.exe" -E -S myhostname -e -b -v .* -i tempfile.sql/)

    execed.should have_sql_property ({:k => "dbname", :v => "regulardb"})
    execed.should have_sql_property ({:k => "dbuser", :v => "theuser"})
    execed.should have_sql_property_count 2

    expected = IO.readlines("data/sqlcmd/expected.sql")
    actual = IO.readlines("data/output/tempfile.sql")

    actual.should == expected
  end

  it "Works fine with system credentials in SQL auth mode" do
    task = BradyW::Sqlcmd.new do |sql|
      sql.files = testdata
      sql.credentials = :system
    end

    task.should_receive(:sql_tool).with("100").and_return("z:\\")

    task.exectaskpublic
    execed = task.executedPop
    execed.should match(/"z:\\sqlcmd\.exe" -U systemuser -P systempassword -S myhostname -e -b -v .* -i tempfile.sql/)

    execed.should have_sql_property ({:k => "dbuser", :v => "theuser"})
    execed.should have_sql_property ({:k => "dbpassword", :v => "thepassword"})
    execed.should have_sql_property ({:k => "sqlserverdatadirectory", :v => "\"F:\\\""})
    execed.should have_sql_property_count 4

    expected = IO.readlines("data/sqlcmd/expected.sql")
    actual = IO.readlines("data/output/tempfile.sql")

    actual.should == expected
  end

  it "Fails properly with invalid credential specifier" do
    task = BradyW::Sqlcmd.new do |sql|
      sql.files = testdata
      lambda { sql.credentials = :foo }.should raise_exception("Invalid credentials value!  Allowed values: :system, :objectcreation, :general")
    end
  end

  it "Works fine with objectcreation credentials in SQL auth mode" do
    task = BradyW::Sqlcmd.new do |sql|
      sql.files = testdata
      sql.credentials = :objectcreation
    end

    task.should_receive(:sql_tool).with("100").and_return("z:\\")

    task.exectaskpublic

    execed = task.executedPop
    execed.should match(/"z:\\sqlcmd\.exe" -U objectcreateuser -P objectcreatepassword -S myhostname -e -b -v .* -i tempfile.sql/)

    execed.should have_sql_property ({:k => "dbname", :v => "regulardb"})
    execed.should have_sql_property ({:k => "dbuser", :v => "theuser"})
    execed.should have_sql_property_count 2

    expected = IO.readlines("data/sqlcmd/expected.sql")
    actual = IO.readlines("data/output/tempfile.sql")

    actual.should == expected
  end

  it "Works fine with system credentials in Win auth mode" do
    def @config.db_system_authmode
      :winauth
    end

    task = BradyW::Sqlcmd.new do |sql|
      sql.files = testdata
      sql.credentials = :system
    end

    task.should_receive(:sql_tool).with("100").and_return("z:\\")

    task.exectaskpublic
    execed = task.executedPop
    execed.should match(/"z:\\sqlcmd\.exe" -E -S myhostname -e -b -v .* -i tempfile.sql/)

    execed.should have_sql_property ({:k => "dbname", :v => "regulardb"})
    execed.should have_sql_property ({:k => "dbuser", :v => "theuser"})
    execed.should have_sql_property ({:k => "sqlserverdatadirectory", :v => "\"F:\\\""})
    execed.should have_sql_property ({:k => "dbpassword", :v => "thepassword"})
    execed.should have_sql_property_count 4

    expected = IO.readlines("data/sqlcmd/expected.sql")
    actual = IO.readlines("data/output/tempfile.sql")

    actual.should == expected
  end

  it "Works fine with additional variables" do
    task = BradyW::Sqlcmd.new do |sql|
      sql.files = testdata
      sql.credentials = :system
      sql.variables = {"var1" => "val1",
                       "dbpassword" => "yesitsoktooverride",
                       "spacevar" => "deals with space right"}
    end

    task.should_receive(:sql_tool).with("100").and_return("z:\\")

    task.exectaskpublic
    execed = task.executedPop
    execed.should match(/"z:\\sqlcmd\.exe" -U systemuser -P systempassword -S myhostname -e -b -v .* -i tempfile.sql/)

    execed.should have_sql_property ({:k => "dbname", :v => "regulardb"})
    execed.should have_sql_property ({:k => "dbuser", :v => "theuser"})
    execed.should have_sql_property ({:k => "dbpassword", :v => "yesitsoktooverride"})
    execed.should have_sql_property ({:k => "var1", :v => "val1"})
    execed.should have_sql_property ({:k => "spacevar", :v => "\"deals with space right\""})
    execed.should have_sql_property ({:k => "sqlserverdatadirectory", :v => "\"F:\\\""})

    execed.should have_sql_property_count 6

    expected = IO.readlines("data/sqlcmd/expected.sql")
    actual = IO.readlines("data/output/tempfile.sql")
    actual.should == expected

  end

  it "Works fine with custom variables" do
    task = BradyW::Sqlcmd.new do |sql|
      sql.files = testdata
      sql.variables = {"var1" => "val1",
                       "dbpassword" => "yesitsoktooverride",
                       "spacevar" => "deals with space right"}
    end

    task.should_receive(:sql_tool).with("100").and_return("z:\\")

    task.exectaskpublic
    execed = task.executedPop
    execed.should match(/"z:\\sqlcmd\.exe" -U theuser -P thepassword -S myhostname -e -b -v .* -i tempfile.sql/)

    execed.should have_sql_property ({:k => "dbname", :v => "regulardb"})
    execed.should have_sql_property ({:k => "dbuser", :v => "theuser"})
    execed.should have_sql_property ({:k => "dbpassword", :v => "yesitsoktooverride"})
    execed.should have_sql_property ({:k => "var1", :v => "val1"})
    execed.should have_sql_property ({:k => "spacevar", :v => "\"deals with space right\""})

    execed.should have_sql_property_count 5

    expected = IO.readlines("data/sqlcmd/expected.sql")
    actual = IO.readlines("data/output/tempfile.sql")
    actual.should == expected

  end

  it "Fails the build properly (and gracefully) if sqlcmd has an error" do
    task = BradyW::Sqlcmd.new do |sql|
      sql.files = testdata
    end

    task.should_receive(:sql_tool).with("100").and_return("z:\\")
    task.stub(:shell).and_yield(nil, SimulateProcessFailure.new)

    lambda { task.exectaskpublic }.should raise_exception("Command failed with status (BW Rake Task Problem):")

    # This means our temporary file was correctly cleaned up
    File.exist?("tempfile.sql").should_not == true
    # Our test code should have done this
    File.exist?("data/output/tempfile.sql").should == true
  end

  it "Properly changes strings to dynamic ones in SQL files" do
    FileUtils::cp_r "data/sqlcmd/makedynamic", "data/output"

    task = BradyW::Sqlcmd.new do |sql|
      sql.files = FileList['data/output/makedynamic/**/*']
      sql.makedynamic = true
    end

    task.exectaskpublic

    task.executedPop.should == nil

    expected = IO.readlines("data/sqlcmd/dynamic_expected.sql")
    actual = IO.readlines("data/output/makedynamic/01-tables/dynamic_input.sql")
    actual.should == expected
  end

end
