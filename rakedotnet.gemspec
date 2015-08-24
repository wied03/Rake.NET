$LOAD_PATH << './lib'
require 'rake'
require 'rakedotnet/version'

src='lib'
testdir='spec'

Gem::Specification.new do |s|
  s.name = 'rakedotnet'
  s.files = FileList["#{src}/**/*.rb",
                     "#{testdir}/**/*.rb"]
  s.test_files = FileList["#{testdir}/**/*.rb"]
  s.version = RakeDotNet::VERSION
  s.summary = 'Rake tasks for building .NET projects'
  s.description = 'Provides MSBuild, NUnit, BCP, SqlCmd, MsTest, MinifyJS, jstest tasks for Rake build files'
  s.has_rdoc = true
  s.license = 'BSD'
  s.homepage = 'https://github.com/wied03/Rake.NET'
  s.rdoc_options << '--inline-source' << '--line-numbers'
  s.author = 'Brady Wied'
  s.email = 'brady@bswtechconsulting.com'
  s.add_runtime_dependency('windows-pr')
  s.add_dependency('bsw_dnet_install_util', '~> 1.0')
  s.require_path = 'lib'
end
