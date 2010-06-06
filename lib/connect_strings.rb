require 'socket'

def prefix
	@props['project']['prefix']
end

def db_name
	@props['db']['name'].gsub(/@thismachinehostname@/, Socket.gethostname).
						 gsub(/@prefix@/, prefix)
end

def db_user
	@props['db']['use']['user'].gsub(/@thismachinehostname@/, Socket.gethostname).
								gsub(/@prefix@/, prefix)	
end

def db_connectstring_code
	prop = @props['db']['connect-strings']
	if @props['db']['use']['mode'] == "winauth"
		prop['winauth'] % [@props['db']['hostname'],
						   db_name]
	else
		prop['sqlauth'] % [@props['db']['hostname'],
						  db_name,
						  db_user,
						  @props['db']['use']['password']]
	end
end

def db_connectstring_sqlcmd
	if @props['db']['use']['mode'] == "winauth"
		"-E -S %s" % [@props['db']['hostname']]
	else
		"-U %s -P %s -S %s" % [db_user,
							   @props['db']['use']['password'],
							   @props['db']['hostname']]
	end
end

def db_connectstring_sqlcmd_create
	if @props['db']['create']['mode'] == "winauth"
		"-E -S %s" % [@props['db']['hostname']]
	else
		"-U %s -P %s -S %s" % [@props['db']['create']['user'],
							   @props['db']['create']['password'],
							   @props['db']['hostname']]
	end
end

def bcp_prefix
	if @props['db']['use']['mode'] == "winauth"
		"%s.dbo." % [db_name]
	else
		""
	end
end

def db_connectstring_bcp
	if @props['db']['auth-windows-normal']
		"-T -S %s" % [@props['db']['hostname']]
	else
		"-U %s -P %s /S%s" % [db_user,
							  @props['db']['password'],
							  @props['db']['hostname']]
	end
end

def db_variables
	{'dbname' => db_name,
	 'sqlserverdatadirectory' => "\"#{@props['db']['data-dir']}\"",
	 'dbuser' => db_user,
	 'dbpassword' => @props['db']['use']['password']}
end