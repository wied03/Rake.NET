$LOAD_PATH << './lib'
require 'rake'

src="lib"
testdir="spec"

Gem::Specification.new do |s|
  s.name = "rakedotnet"
  s.files = FileList["#{src}/**/*.rb",
                     "#{testdir}/**/*.rb"]
  s.test_files = FileList["#{testdir}/**/*.rb"]
  s.version = env['version_number']
  s.summary = "Rake tasks for building .NET projects"
  s.description = s.summary      
  s.has_rdoc = true
  s.rdoc_options << '--inline-source' << '--line-numbers'
  s.author = "Brady Wied"
  s.email = "brady@wied.us"          
  s.add_dependency('windows-pr')  
end
