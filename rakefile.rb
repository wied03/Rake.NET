require 'psych'
require 'rake/clean'
require 'rubygems'
require 'rspec/core/rake_task'
require './lib/tools'

task :ci => [:clean,:spec,:gem,:pushtorepo]

task :clean do
	rm_rf FileList["*.gem"]
end

with("spec") do |testdir|
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = FileList["#{testdir}/**/*_spec.rb"]
  end
end

task :gem do
	system "gem build .gemspec"
end

task :pushtorepo do
	url = ENV['repo']	
	system "gem inabox #{FileList["*.gem"]} -g #{url}"
end
