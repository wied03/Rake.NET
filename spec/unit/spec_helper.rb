require 'rspec/expectations'
# Needed to mock out our config/props
require 'rakedotnet'
require 'task_helper'

include FileUtils

def simulate_redirected_log_output(task, options)
  # STDOUT redirects on Windows seem to come back like this
  options = {:file_write_options => 'w:UTF-16LE:ascii', :failure_return_code => false}.merge(options.is_a?(Hash) ? options : {:file_name => options})
  allow(task).to receive(:shell) { |*commands, &block|
                   # Simulate dotNetInstaller logging to the file
                   File.open options[:file_name], options[:file_write_options] do |writer|
                     yield writer
                   end
                   puts commands
                   @commands = commands
                   failure = options[:failure_return_code] ? SimulateProcessFailure.new : nil
                   block.call(nil, failure) if block
                 }
end


