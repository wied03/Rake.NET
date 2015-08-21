Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'

task :default => [:clean, :spec, :build]

task :clean do
  rm_rf FileList['*.gem']
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--default-path spec/unit'
end
