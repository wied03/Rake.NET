require 'msbuild'

with('Distribution') do |dist|
	BW::MinifyJs.new "minify_js" do |js|
		js.files = FileList["#{dist}/frontend/*.js"]
	end
end

BW::JsTest.new "jstest" do |j|
	j.browsers = @props['test']['javascript']['browsers']
	j.port = @props['test']['javascript']['port']
end

with('Database') do |d|
	BW::BCP.new "db_data" do |bcp|
		bcp.files = FileList["#{d}/data/*.csv"]
    end

    BW::Sqlcmd.new "db_schema" do |db|
      db.usecreatecredentials = true
      db.files = FileList["#{d}/schema/create_database.sql"]
    end

    BW::Sqlcmd.new "db_drop" do |db|
      db.usecreatecredentials = true
      db.files = FileList["#{d}/schema/drop_database.sql"]
    end

    BW::Sqlcmd.new "db_objects" do |db|
      db.files = FileList["#{d}/objects/**/*"]
    end
end

with('MvcApplication1.sln') do |solution|
	BW::MSBuild.new "clean" do |clean|
		clean.target = "clean"
		clean.solution = solution
	end

	BW::MSBuild.new "build" do |build|
		build.solution = solution
	end
end

task :test => [:codetest, :jstest]

with ('test') do |t|
	BW::MSTest.new "codetest" => :build do |test|
		test.files = FileList["#{t}/**/bin/Debug/*.Tests.dll"]
	end
end

BW::Iis.new "iis_start" do |iis|
	iis.command = "START"
end

BW::Iis.new "iis_stop" do |iis|
	iis.command = "STOP"
end