require "base"
require "db"

describe BW::DB do
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

  it "General props" do
    @props["db"][:general.to_s] = "foo"
    @db.general.should == "foo"
  end

  it "User plain" do
    @props["db"][:general.to_s] = {"user" => "username"}
    @db.user.should == "username"
  end

  it "Password" do
    @props["db"][:general.to_s] = {"password" => "thepassword"}
    @db.password.should == "thepassword"
  end

  it "User hostname/prefix" do
    @props["db"][:general.to_s] = {"user" => "@prefix@-@thismachinehostname@"}
    @db.user.should == "PRE-"+Socket.gethostname
  end

  it "Connect String for .NET Code/SQL Auth" do
    @props["db"]["hostname"] = "myhostname"
    @props['db'][:general.to_s] = {"mode" => "sqlauth",
                                   "user" => "theuser",
                                   "password" => "thepassword"}
    
    @props['db']["connect-strings"] =
             {"sqlauth" => "user @user@ pass @password@ host @host@ db @initialcatalog@"}
    @db.connect_code.should == "user theuser pass thepassword host myhostname db regulardb"
  end

  it "Connect String for .NET Code/Windows Auth" do
    @props["db"]["hostname"] = "myhostname"
    @props['db'][:general.to_s] = {"mode" => "winauth"}

    @props['db']["connect-strings"] =
             {"winauth" => "host @host@ db @initialcatalog@"}
    @db.connect_code.should == "host myhostname db regulardb"
  end
end