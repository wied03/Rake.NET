require 'rakedotnet'

desc 'Builds NuGet packages'
file 'packages' => FileList['**/packages.config'] do
	sh 'tools/nuget.exe restore RakeDotNet.sln'
end

BradyW::MSBuild.new :clean do |clean|
  clean.targets = 'clean'
end

BradyW::MSBuild.new :build => :packages
