require 'psych'
require 'rake/clean'
require 'rubygems'
require 'rspec/core/rake_task'
require './lib/version'
require './lib/tools'

task :ci => :spec

with("spec") do |testdir|
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = FileList["#{testdir}/**/*_spec.rb"]
  end
end