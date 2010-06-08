require "base"

describe "SQLCMD Testing" do
  before(:each) do
    @props = {}
    BW::Config.stub!(:Props).and_return(@props)
    @db = BW::DB.new
    @props["db"] = {"name" => "regulardb"}
    @props["project"] = {"prefix" => "PRE"}
  end
  
  it "Connect String for SQLCMD / SQL Auth" do
    @props["db"]["hostname"] = "myhostname"
    @props['db']["use"] = {"mode" => "sqlauth",
                           "user" => "theuser",
                           "password" => "thepassword"}

    @db.connect_sqlcmd.should == "-U theuser -P thepassword -S myhostname"
  end

  it "Connect String for SQLCMD / Win Auth" do
    @props["db"]["hostname"] = "myhostname"
    @props['db']["use"] = {"mode" => "winauth"}

    @db.connect_sqlcmd.should == "-E -S myhostname"
  end

  it "Connect String for SQLCMD (Create) / SQL Auth" do
    @props["db"]["hostname"] = "myhostname"
    @props['db']["create"] = {"mode" => "sqlauth",
                              "user" => "theuser",
                              "password" => "thepassword"}

    @db.connect_sqlcmd_create.should == "-U theuser -P thepassword -S myhostname"
  end

  it "Connect String for SQLCMD (Create) / Win Auth" do
    @props["db"]["hostname"] = "myhostname"
    @props['db']["create"] = {"mode" => "winauth"}

    @db.connect_sqlcmd_create.should == "-E -S myhostname"
  end

  it "Should should set DB variables properly" do
    false.should == true
  end
end