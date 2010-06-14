require 'rake'
require 'rubygems'
require 'rake/gempackagetask'
require 'spec/rake/spectask'
require 'rake/rdoctask'
require 'lib/version'

Spec::Rake::SpecTask.new :spec do |t|
  t.spec_files = FileList['test/**/*_spec.rb']
  t.spec_opts << '--format specdoc'
  t.libs = FileList['test']
end

task :clean_install => [:repackage, :install]

task :install do
  sh "gem install " +FileList['pkg/*.gem'].first()
  sh "gem cleanup raketasks"
end

spec = Gem::Specification.new do |s|
  s.name = 'raketasks'
  s.version = BW::Version.incrementandretrieve
  s.summary = "Rake tasks for building .NET projects"
  s.description = s.summary
  s.files = FileList['lib/**/*.rb', 'test/**/*.rb']
  s.test_files = FileList['test/**/*.rb']
  s.has_rdoc = false
  s.author = "Brady Wied"
  s.email = "brady@wied.us"
  s.add_dependency('fastercsv', '>= 1.5.0')
  s.add_dependency('bwyamlconfig')
  s.add_dependency('windows-pr')
  s.platform = 'mswin32'
end

Rake::GemPackageTask.new(spec) do |pkg|
end

Rake::RDocTask.new do |rd|
  rd.rdoc_dir = 'doc/rdocs'
  rd.rdoc_files.include "lib/**/*"
  rd.options << '--inline-source'
  rd.options << '--line-numbers'
end