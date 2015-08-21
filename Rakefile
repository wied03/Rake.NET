Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'

task :default => [:clean, :spec, :integration, :build]

task :clean do
  rm_rf FileList['*.gem']
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/unit/**/*_spec.rb'
  t.ruby_opts = '-Ispec/unit'
end

RSpec::Core::RakeTask.new(:integration) do |t|
  t.pattern = 'spec/integration/**/*_spec.rb'
  t.ruby_opts = '-Ispec/integration'
end
