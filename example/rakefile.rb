require 'bwbuild/package'

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
		bcp.prefix = bcp_prefix
		bcp.connect_string = db_connectstring_bcp
		bcp.files = FileList["#{d}/data/*.csv"]
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