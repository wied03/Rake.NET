require 'rake'
require 'rubygems'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = 'raketasks'
  s.version = '1.0.0'
  s.summary = "Rake tasks for building .NET projects"
  s.description = "Rake tasks for building .NET projects"
  s.files = FileList['lib/**/*.rb', 'test/**/*.rb']
  s.test_files = FileList['test/**/*.rb']
  s.has_rdoc = false
  s.author = "Brady Wied"
  s.email = "brady@wied.us"
  s.add_dependency('fastercsv', '>= 1.5.0')
  s.platform = 'mswin32'
end

Rake::GemPackageTask.new(spec) do |pkg|
end 