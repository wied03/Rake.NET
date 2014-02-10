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
      msi_log_file = TempFileNameGenerator.random_filename 'msi_log', '.txt'
      @msiexec_arguments = {'l*' => msi_log_file}
      params = ["/#{mode_switch}"]
      params << param_fslash('ComponentArgs', properties_flat)
      params << '/q'
      dnet_inst_log_file = TempFileNameGenerator.random_filename 'dnet_log', '.txt'
      clean_file = lambda {
        FileUtils.rm dnet_inst_log_file
        FileUtils.rm msi_log_file
      }
      params << '/Log'
      params << param_fslash('LogFile', dnet_inst_log_file)
      params_flat = params.join ' '
      shell "#{elevate_and_exe_path} #{params_flat}" do |ok, status|
        log ".NET Installer Log"
        success = write_dnet_installer_log_to_console dnet_inst_log_file
        log "\nMSI Log:"
        write_msi_log_to_console msi_log_file
        clean_file.call unless preserve_temp_files
        puts 'Successful return code, task finished' if success
        fail 'Due to lack of success message in logs, this task has failed' unless success
      end
    end

    private

    def write_dnet_installer_log_to_console(filename)
      regex = /dotNetInstaller finished, return code: 0 \(0x0\)/
      # the .net installer log is written with 'standard' encoding
      success = false
      send_log_file_contents_to_console :log_file_name => filename, :file_read_options => 'r' do |line_being_logged|
        if regex.match line_being_logged
          success = true
        end
      end
      success
    end

    def write_msi_log_to_console(filename)
      send_log_file_contents_to_console(:log_file_name => filename)
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
      # nil values can be sent to the MSI inside quotes
      value = '' if !value
      quotes_handled = double_the_quotes value
      spaces_handled = quotes_handled.include?(' ') || value == '' ? quoted(quotes_handled) : quotes_handled
      # Need 4x the quotes for property values that contain quotes and 2X the quotes when we surround with a quote due to a space
      double_the_quotes spaces_handled
    end

    def properties_flat
      props_list = @msiexec_arguments.map { |k, v| param_fslash(k, escape_prop_value(v)) }
      props_list << properties.map { |k, v| "#{k}=#{escape_prop_value(v)}" } if @properties
      props_flat = props_list.join ' '
      "*:\"#{props_flat}\""
    end

    def mode_switch
      @mode == :install ? 'i' : 'x'
    end
  end
end