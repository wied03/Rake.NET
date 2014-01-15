require 'basetask'
require 'param_quotes'
require 'temp_file_name_generator'
require 'path_fetcher'

module BradyW
  class DotNetInstallerExecute < BaseTask
    include ParamQuotes

    # *Required* Either :install or :uninstall
    attr_accessor :mode

    # *Optional* Which MSI property values should be passed to the install for all components
    attr_accessor :properties

    # *Required* The path to the installer to execute
    attr_accessor :path

    def exectask
      validate
      params = ["/#{mode_switch}"]
      params << param_fslash('ComponentArgs', properties_flat) if @properties && @mode == :install
      params << '/q'
      log_file = TempFileNameGenerator.filename 'log.txt'
      clean_file = lambda { FileUtils.rm log_file unless ENV['PRESERVE_TEMP'] }
      params << '/Log'
      params << param_fslash('LogFile', log_file)
      params_flat = params.join ' '
      shell "#{elevate_and_exe_path} #{params_flat}" do |ok, status|
        contents = get_file_contents log_file
        puts contents
        puts 'Ignoring return code since these seem to invalid, instead checking log file for success'
        success = contents.match(/dotNetInstaller finished, return code: 0 \(0x0\)/)
        clean_file.call
        puts 'Successful return code, task finished' if success
        fail 'Due to failure message in logs, this task has failed' unless success
      end
    end

    private

    def get_file_contents(src_file_name)
      text = ''
      File.open src_file_name, 'r' do |input|
        input.each do |line|
          text << line
        end
      end
      text
    end

    def elevate_and_exe_path
      # Elevate.exe needs windows style backslash path here and needs to wait for elevation to complete
      exe_path = path.gsub(/\//, '\\')
      "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"#{exe_path}\""
    end

    def validate
      raise 'mode and path are required' unless @mode && @path
      raise "mode cannot be :#{@mode}, must be either :install or :uninstall" unless [:install, :uninstall].include?(@mode)
    end

    def double_the_quotes value
      value.gsub /\"/, '""'
    end

    def escape_prop_value value
      quotes_handled = double_the_quotes value
      spaces_handled = quotes_handled.include?(' ') ? quoted(quotes_handled) : quotes_handled
      # Need 4x the quotes for property values that contain quotes and 2X the quotes when we surround with a quote due to a space
      double_the_quotes spaces_handled
    end

    def properties_flat
      props_list = properties.map { |k, v| "#{k}=#{escape_prop_value(v)}" }
      props_flat = props_list.join ' '
      "*:\"#{props_flat}\""
    end

    def mode_switch
      @mode == :install ? 'i' : 'x'
    end
  end
end