Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'
require './lib/util/tools'

task :default => [:clean,:spec,:build]

task :clean do
	rm_rf FileList['*.gem']
end

with('spec') do |testdir|
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = FileList["#{testdir}/**/*_spec.rb"]
  end
end
