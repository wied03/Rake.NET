require 'spec_helper'

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

    def @config.db_connect_string_sqlauth
      "user @user@ pass @password@ host @host@ db @initialcatalog@"
    end

    @db.connect_code.should == "user theuser pass thepassword host myhostname db regulardb"
  end

  it "Connect String for .NET Code/Windows Auth" do
    def @config.db_hostname
          "myhostname"
    end

    def @config.db_general_authmode
          :winauth
    end

    def @config.db_connect_string_winauth
      "host @host@ db @initialcatalog@"
    end

    @db.connect_code.should == "host myhostname db regulardb"
  end
end