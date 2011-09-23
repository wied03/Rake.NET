require "base"
require "sqlcmd"
require "basetaskmocking"

def testdata
  FileList["data/sqlcmd/input/**/*"]
end

describe BW::Sqlcmd do
  RSpec::Matchers.define :have_sql_property do |expected|
    match do |actual|
      actualProps = parseProps actual
      actualProps.include? expected
    end

    def parseProps (actual)
        actualProps = actual.match(/.*-v (.+) -/)[1].scan(/('.*?'|\S+=".*?"|\S+)/).map do |kv|
        arr = kv[0].split('=')
        {:k => arr[0], :v =>arr[1]}
        end
        actualProps
    end
  end

  RSpec::Matchers.define :have_sql_property_count do |expected|
    match do |actual|
      actualProps = parseProps actual
      actualProps.should have(expected).items
    end

    def parseProps (actual)
        actual.match(/.*-v (.+) -/)[1].scan(/('.*?'|\S+=".*?"|\S+)/)
    end
  end

  before(:each) do
    # It uses the current date, which is harder to test
    BW::Sqlcmd.stub!(:generatetempfilename).and_return "tempfile.sql"
  end
  
  before(:each) do    
    @db = BW::DB.new
    @props["db"] = {"name" => "regulardb",
                    "hostname" => "myhostname"}
    @props["project"] = {"prefix" => "PRE"}
    @props['db'][:general.to_s] = {"mode" => "sqlauth",
                                   "user" => "theuser",
                                   "password" => "thepassword"}
    @props['db'][:system.to_s] = {"mode" => "sqlauth",
                                  "user" => "systemuser",
                                  "password" => "systempassword",
                                  "data-dir" => "F:\\"}
    @props['db'][:objectcreation.to_s] = {"mode" => "sqlauth",
                                          "user" => "objectcreateuser",
                                          "password" => "objectcreatepassword"}
  end

  after(:each) do
    # Remove our generated test data
    FileUtils::rm_rf "data/output/tempfile.sql"
    FileUtils::rm_rf "data/output/makedynamic"
  end

  it "Should work with default version and default (non create) credentials in SQL auth mode" do
    task = BW::Sqlcmd.new do |sql|
      sql.files = testdata
    end

    task.should_receive(:sql_tool).any_number_of_times.with("100").and_return("z:\\")

    task.exectaskpublic
    execed = task.excecutedPop
    execed.should match(/"z:\\sqlcmd\.exe\" -U theuser -P thepassword -S myhostname -e -b -v .* -i tempfile.sql/)

    execed.should have_sql_property ({:k => "dbname", :v => "regulardb"})
    execed.should have_sql_property ({:k => "dbuser", :v => "theuser"})
    execed.should have_sql_property_count 2

    expected = IO.readlines("data/sqlcmd/expected.sql")
    actual = IO.readlines("data/output/tempfile.sql")

    actual.should == expected
  end

  it "Should work with a custom version and default (non create) credentials in Win auth mode" do
    @props['db'][:general.to_s]["mode"] = "winauth"

    task = BW::Sqlcmd.new do |sql|
      sql.files = testdata
      sql.version = "902"
    end

    task.should_receive(:sql_tool).any_number_of_times.with("902").and_return("z:\\")

    task.exectaskpublic

    execed = task.excecutedPop
    execed.should match(/"z:\\sqlcmd\.exe\" -E -S myhostname -e -b -v .* -i tempfile.sql/)

    execed.should have_sql_property ({:k => "dbname", :v => "regulardb"})
    execed.should have_sql_property ({:k => "dbuser", :v => "theuser"})
    execed.should have_sql_property_count 2

    expected = IO.readlines("data/sqlcmd/expected.sql")
    actual = IO.readlines("data/output/tempfile.sql")

    actual.should == expected
  end

  it "Works fine with system credentials in SQL auth mode" do
    task = BW::Sqlcmd.new do |sql|
      sql.files = testdata
      sql.credentials = :system
    end

    task.should_receive(:sql_tool).any_number_of_times.with("100").and_return("z:\\")

    task.exectaskpublic
    execed = task.excecutedPop
    execed.should match(/"z:\\sqlcmd\.exe\" -U systemuser -P systempassword -S myhostname -e -b -v .* -i tempfile.sql/)

    execed.should have_sql_property ({:k => "dbuser", :v => "theuser"})
    execed.should have_sql_property ({:k => "dbpassword", :v => "thepassword"})
    execed.should have_sql_property ({:k => "sqlserverdatadirectory", :v => "\"F:\\\""})
    execed.should have_sql_property_count 4

    expected = IO.readlines("data/sqlcmd/expected.sql")
    actual = IO.readlines("data/output/tempfile.sql")

    actual.should == expected 
  end

  it "Fails properly with invalid credential specifier" do
    task = BW::Sqlcmd.new do |sql|
      sql.files = testdata
      lambda {sql.credentials = :foo}.should raise_exception("Invalid credentials value!  Allowed values: :system, :objectcreation, :general")
    end    
  end

  it "Works fine with objectcreation credentials in SQL auth mode" do
    task = BW::Sqlcmd.new do |sql|
      sql.files = testdata
      sql.credentials = :objectcreation
    end

    task.should_receive(:sql_tool).any_number_of_times.with("100").and_return("z:\\")

    task.exectaskpublic

    execed = task.excecutedPop
    execed.should match(/"z:\\sqlcmd\.exe\" -U objectcreateuser -P objectcreatepassword -S myhostname -e -b -v .* -i tempfile.sql/)

    execed.should have_sql_property ({:k => "dbname", :v => "regulardb"})
    execed.should have_sql_property ({:k => "dbuser", :v => "theuser"})
    execed.should have_sql_property_count 2

    expected = IO.readlines("data/sqlcmd/expected.sql")
    actual = IO.readlines("data/output/tempfile.sql")

    actual.should == expected
  end

  it "Works fine with system credentials in Win auth mode" do
    @props['db'][:system.to_s]["mode"] = "winauth"

    task = BW::Sqlcmd.new do |sql|
      sql.files = testdata
      sql.credentials = :system
    end

    task.should_receive(:sql_tool).any_number_of_times.with("100").and_return("z:\\")

    task.exectaskpublic
     execed = task.excecutedPop
    execed.should match(/"z:\\sqlcmd\.exe\" -E -S myhostname -e -b -v .* -i tempfile.sql/)

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
    task = BW::Sqlcmd.new do |sql|
      sql.files = testdata
      sql.credentials = :system
      sql.variables = { "var1" => "val1",
                        "dbpassword" => "yesitsoktooverride",
                        "spacevar" => "deals with space right"}
    end

    task.should_receive(:sql_tool).any_number_of_times.with("100").and_return("z:\\")

    task.exectaskpublic
    execed = task.excecutedPop
    execed.should match(/"z:\\sqlcmd\.exe\" -U systemuser -P systempassword -S myhostname -e -b -v .* -i tempfile.sql/)

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
    task = BW::Sqlcmd.new do |sql|
      sql.files = testdata
      sql.variables = { "var1" => "val1",
                        "dbpassword" => "yesitsoktooverride",
                        "spacevar" => "deals with space right"}
    end

    task.should_receive(:sql_tool).any_number_of_times.with("100").and_return("z:\\")

    task.exectaskpublic
    execed = task.excecutedPop
    execed.should match(/"z:\\sqlcmd\.exe\" -U theuser -P thepassword -S myhostname -e -b -v .* -i tempfile.sql/)

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
    task = BW::Sqlcmd.new do |sql|
      sql.files = testdata
    end

    task.should_receive(:sql_tool).any_number_of_times.with("100").and_return("z:\\")
    task.stub!(:shell).and_yield(nil, SimulateProcessFailure.new)
    
    lambda {task.exectaskpublic}.should raise_exception("Command failed with status (BW Rake Task Problem):")

    # This means our temporary file was correctly cleaned up
    File.exist?("tempfile.sql").should_not == true
    # Our test code should have done this 
    File.exist?("data/output/tempfile.sql").should == true    
  end

  it "Properly changes strings to dynamic ones in SQL files" do
    FileUtils::cp_r "data/sqlcmd/makedynamic", "data/output"

    task = BW::Sqlcmd.new do |sql|
      sql.files = FileList['data/output/makedynamic/**/*']
      sql.makedynamic = true
    end

    task.exectaskpublic

    task.excecutedPop.should == nil

    expected = IO.readlines("data/sqlcmd/dynamic_expected.sql")
    actual = IO.readlines("data/output/makedynamic/01-tables/dynamic_input.sql")
    actual.should == expected
  end
  
end