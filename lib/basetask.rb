require 'rake'
require 'rake/tasklib'

module BradyW

  # Used to abstract some of the functionality of building custom tasks in Rake out
  # and also provide a convenient point to mock them for testing purposes
  class BaseTask < Rake::TaskLib
    attr_accessor :name, :unless

    protected

    def preserve_temp_files
      ENV['PRESERVE_TEMP'] != nil
    end

    # Validates whether value is in the allowed list and raises an exception, using name
    # as documentation, if it does not
    def self.validate(value, name, allowed)
      if !allowed.include? value
        symbols = allowed.collect { |sym| ":#{sym}" }
        formatted = symbols.join(", ")
        raise "Invalid #{name} value!  Allowed values: #{formatted}"
      end
    end

    def initialize(parameters = :task)
      parseParams parameters
      yield self if block_given?
      task @name => @dependencies if @dependencies unless @unless
      define
    end

    # Setup here for mocking purposes and also to stop verbose messages from ending up
    # in stderr and causing CruiseControl.net to display errors
    def shell(*cmd, &block)
      options = (Hash === cmd.last) ? cmd.pop : {}
      options[:verbose] = false
      command = cmd.first
      puts "Running #{command} via Rake sh"
      sh command, options, &block
    end

    def windows_friendly_path(path)
      path.gsub(/\//, '\\')
    end

    def send_log_file_contents_to_console(options)
      log_file_name = options.is_a?(Hash) ? options[:log_file_name] : options
      # When Windows STDOUT redirects are written, they've been in this encoding
      opts = {:file_read_options => 'r:UTF-16LE:ascii'}
      opts.merge!(options) if options.is_a?(Hash)
      File.open log_file_name, opts[:file_read_options] do |file|
        file.each_line do |line|
          log line
          yield line if block_given?
        end
      end
    end

    private

    def parseParams parameters
      @name = case parameters
                when Hash
                  n = parameters.keys[0]
                  @dependencies = parameters[n]
                  n
                else
                  parameters
              end
    end

    # Create the tasks defined by this task lib.
    def define
      task name do
        if not @unless
          log "Running task: #{@name}"
          exectask
        else
          log "Skipping task: #{@name} due to unless condition specified in rakefile"
        end
      end
      self
    end

    def log text
      puts text
    end
  end
end