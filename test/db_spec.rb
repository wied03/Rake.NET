require "base"
require "db"

describe "Database Utilities" do
  before(:each) do
    @db = BW::DB.new
    @props["db"] = {"name" => "regulardb"}
    @props["project"] = {"prefix" => "PRE"}
  end

  it "DB Name Plain" do
    @db.name.should == "regulardb"
  end

  it "DB Name with hostname/prefix" do
    @props["db"]["name"] = "@prefix@-@thismachinehostname@"
    @db.name.should == "PRE-"+Socket.gethostname
  end

  it "User plain" do
    @props["db"]["use"] = {"user" => "username"}
    @db.user.should == "username"
  end

  it "User hostname/prefix" do
    @props["db"]["use"] = {"user" => "@prefix@-@thismachinehostname@"}
    @db.user.should == "PRE-"+Socket.gethostname
  end

  it "Connect String for .NET Code/SQL Auth" do
    @props["db"]["hostname"] = "myhostname"
    @props['db']["use"] = {"mode" => "sqlauth",
                           "user" => "theuser",
                           "password" => "thepassword"}
    
    @props['db']["connect-strings"] =
             {"sqlauth" => "user @user@ pass @password@ host @host@ db @initialcatalog@"}
    @db.connect_code.should == "user theuser pass thepassword host myhostname db regulardb"
  end

  it "Connect String for .NET Code/Windows Auth" do
    @props["db"]["hostname"] = "myhostname"
    @props['db']["use"] = {"mode" => "winauth"}

    @props['db']["connect-strings"] =
             {"winauth" => "host @host@ db @initialcatalog@"}
    @db.connect_code.should == "host myhostname db regulardb"
  end
end