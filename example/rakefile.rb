require "bcp"
require "sqlcmd"
require "tools"
require "jstest"
require "config"
require "minifyjs"
require "msbuild"
require "mstest"
require "iis"

@props = BW::Config.Props
with("Javascript") do |js|
	BW::JsTest.new :jstest do |j|
		j.files = FileList["#{js}/src/**/*.js",
						   "#{js}/test/**/*.js"]
		j.browsers = @props['test']['javascript']['browsers']
		j.port = @props['test']['javascript']['port']
	end
end

with('Distribution') do |dist|
	BW::MinifyJs.new :minify_js do |js|
		js.files = FileList["#{dist}/frontend/*.js"]
	end
end

with('MvcApplication1.sln') do |solution|
	BW::MSBuild.new :clean do |clean|
		clean.targets = "clean"
		clean.solution = solution
	end

	BW::MSBuild.new :build do |build|
		build.solution = solution
	end
end

task :test => [:codetest, :jstest]

with ('test') do |t|
	BW::MSTest.new :codetest => :build do |test|
		test.files = FileList["#{t}/**/bin/Debug/*.Tests.dll"]
	end
end

BW::IIS.new :iis_start do |iis|
	iis.command = :start
end

BW::IIS.new :iis_stop do |iis|
	iis.command = :stop
end

with('Database') do |d|
	BW::BCP.new :db_data do |bcp|
		bcp.files = FileList["#{d}/data/*.csv"]
        bcp.identity_inserts = true
    end

	task :db => [:db_schema, :db_objects]
	
	task :db_schema => [:db_schema_create,
						:db_schema_grant]
	
    BW::Sqlcmd.new :db_schema_create do |db|
      db.usecreatecredentials = true
      db.files = FileList["#{d}/schema/create_database.sql"]
    end
	
	BW::Sqlcmd.new :db_schema_grant do |db|
	  db.usecreatecredentials = true
	  db.files = FileList["#{d}/schema/grant_sqlauth.sql"]
	end
	
	task :db_drop => [:db_schema_revoke, :db_schema_drop]
	
	BW::Sqlcmd.new :db_schema_revoke do |db|
	  db.usecreatecredentials = true
	  db.files = FileList["#{d}/schema/revoke_sqlauth.sql"]
	end
	
    BW::Sqlcmd.new :db_schema_drop do |db|
      db.usecreatecredentials = true
      db.files = FileList["#{d}/schema/drop_database.sql"]
    end

    BW::Sqlcmd.new :db_objects do |db|
      db.files = FileList["#{d}/objects/**/*"]
    end
	
	BW::Sqlcmd.new :db_replacevars do |db|
	  db.makedynamic = true
      db.files = FileList["#{d}/objects/**/*"]
    end
end

