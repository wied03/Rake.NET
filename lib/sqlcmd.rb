module BW
  class Sqlcmd < BaseTask
    include BW::WindowsPaths

    private
    # Connect string to use with SQLCMD while creating tables/indexes/etc. (NOT creating a database)
    def connect_sqlcmd
        if dbprops['use']['mode'] == "winauth"
            "-E -S %s" % [host]
        else
            "-U %s -P %s -S %s" % [user,
                                   dbprops['use']['password'],
                                   host]
        end
    end

    # Connect string to use with SQLCMD while creating a database
    def connect_sqlcmd_create
        if dbprops['create']['mode'] == "winauth"
            "-E -S %s" % [host]
        else
            "-U %s -P %s -S %s" % [dbprops['create']['user'],
                                   dbprops['create']['password'],
                                   host]
        end
    end
    
    def variables
        {'dbname' => db_name,
         'sqlserverdatadirectory' => "\"#{dbprops['data-dir']}\"",
         'dbuser' => db_user,
         'dbpassword' => dbprops['use']['password']}
    end
  end
end