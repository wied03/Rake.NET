$LOAD_PATH << './lib'
require 'rake'
require 'version'

src="lib"
testdir="spec"

Gem::Specification.new do |s|
  s.name = "rakedotnet"
  s.files = FileList["#{src}/**/*.rb",
                     "#{testdir}/**/*.rb"]
  s.test_files = FileList["#{testdir}/**/*.rb"]
  s.version = BW::Version.incrementandretrieve
  s.summary = "Rake tasks for building .NET projects"
  s.description = s.summary      
  s.has_rdoc = true
  s.rdoc_options << '--inline-source' << '--line-numbers'
  s.author = "Brady Wied"
  s.email = "brady@wied.us"        
  s.add_dependency('bwyamlconfig')
  s.add_dependency('windows-pr')
  s.platform = 'mswin32'
end
