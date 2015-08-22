RSpec.shared_context :io_helper do
  def read_file_in_bin_mode(filename)
    File.open(filename, 'rb') do |file|
      file.readlines
    end
  end

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
end
