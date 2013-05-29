require "base"
require "database"

describe BradyW::Database do
  before(:each) do
    @db = BradyW::Database.new
    def @config.db_name
          "regulardb"
    end
    def @config.project_prefix
      "PRE"
    end
  end

  it "DB Name Plain" do
    @db.name.should == "regulardb"
  end

  it "DB Name with hostname/prefix" do
    def @config.db_name
      "@prefix@-@thismachinehostname@"
    end
    @db.name.should == "PRE-"+Socket.gethostname
  end

  it "User plain" do
    def @config.db_general_user
      "username2"
    end

    @db.user.should == "username2"
  end

  it "Password" do
    def @config.db_general_password
        "thepassword"
    end

    @db.password.should == "thepassword"
  end

  it "User hostname/prefix" do
    def @config.db_general_user
          "@prefix@-@thismachinehostname@"
    end
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