require_relative '../basetask'
require_relative '../util/dot_net_version_symbol_to_number_converter'
require_relative '../util/param_quotes'
require_relative '../util/temp_file_name_generator'
require 'path_fetcher'

module BradyW
  class Nunit < BaseTask
    include DotNetVersionSymbolToNumberConverter
    include ParamQuotes
    PROGRAM_FILES_DIR = 'C:/Program Files (x86)'

    # *Required* Files/assemblies to test.  You can also override this each time by setting the environment variable 'nunit_filelist' to a glob pattern
    attr_accessor :files

    # *Optional* Version of NUnit in use, defaults to 2.6.3
    attr_accessor :version

    # *Optional* What version of the .NET framework to use for the tests?  :v2_0, :v3_5, :v4_0, :v4_5, defaults to :v4_5
    attr_accessor :framework_version

    # *Optional* Path where nunit-console.exe lives, defaults to C:\Program Files (x86)\NUnit ${version}\bin
    attr_accessor :base_path

    # *Optional* Timeout for each test case in milliseconds, by default the timeout is 35 seconds
    attr_accessor :timeout

    # *Optional* Which tests should be run (specify namespace+class), can be multiple, defaults to all in class
    attr_accessor :tests

    # *Optional* Should XML be outputted?  By default the answer is no, but set this to :enabled if you want XML output
    attr_accessor :xml_output

    # *Optional* If NUnit should be run as a different user, supply the username here.  You must supply :run_as_password as well
    attr_accessor :run_as_user

    # *Optional* The password for the user specified under :run_as_user
    attr_accessor :run_as_password

    # *Optional* Should labels be printed in the test output, default is :include_labels, can also say :exclude_labels
    attr_accessor :labels

    # *Optional* Where should test output be stored?  Default is console
    attr_accessor :output

    # *Optional* Where should test errors be stored?  Default is console
    attr_accessor :errors

    # *Optional* Should :x86 or :anycpu archiecture be used?  Default is :anycpu
    attr_accessor :arch

    # *Optional* :elevated, :normal :normal by default.  if :elevated, XML output will be enabled
    attr_accessor :security_mode

    # *Optional* If using :elevated security_mode or :run_as_user, you can specify which environment variables you want passed on to the NUnit console process here.  If not using elevated mode, this is ignored
    attr_accessor :environment_variables

    private

    def exectask
      if security_mode == :elevated
        run_elevated
      elsif @run_as_user
        run_as_user
      else
        run_standard
      end
    end

    def get_nunit_console_command_line
      # Elevated NUnit runs in a separate window and we won't see its output in the build script
      if security_mode == :elevated or @run_as_user
        @xml_output = :enabled
        @custom_output = @output != nil
        temp_file = TempFileNameGenerator.random_filename('nunitoutput', '.txt') unless @custom_output
        @output = temp_file if temp_file
      end
      tparm = testsparam
      params = [output,
                errors,
                labels_flat,
                xml_output_flat,
                param_fslash_eq('framework', framework_version),
                param_fslash_eq('timeout', timeout),
                tparm ? param_fslash_eq('run', tparm) : '']
      params << get_assemblies
      params.reject! { |p| !p || p.empty? }
      "#{quoted(full_path)} #{params.join(' ')}"
    end

    def run_standard
      shell get_nunit_console_command_line
    end

    def environment_variable_lines
      @environment_variables.map { |var, val| "set #{var}=#{val}\r\n" }
    end

    def run_as_user
      ps_tools_path = File.join BswTech::DnetInstallUtil.ps_tools_base_path, 'PsExec.exe'
      run_using_delegate_process do |batch_file_path|
        shell "#{ps_tools_path} -u #{@run_as_user} -p #{run_as_password} -i #{batch_file_path}"
      end
    end

    def run_elevated
      run_using_delegate_process do |batch_file_path|
        shell "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w #{batch_file_path}"
      end
    end

    # Yields the full quoted path to the batch file that will run NUnit
    def run_using_delegate_process
      temp_batch_file_name = TempFileNameGenerator.random_filename('run_nunit_elevated', '.bat')
      cleanup = lambda {
        FileUtils.rm @output
        FileUtils.rm temp_batch_file_name
      }
      # Need to use binary mode to avoid CRLF/Windows issues since it's picky about batch files
      File.open temp_batch_file_name, 'wb' do |file|
        environment_variable_lines.each { |line| file << line } if @environment_variables
        file << "cd #{Rake.original_dir}\r\n"
        file << get_nunit_console_command_line
      end
      begin
        full_path = File.expand_path temp_batch_file_name
        yield quoted(windows_friendly_path(full_path))
      ensure
        # Elevated NUnit runs in a separate window and we won't see its output in the build script
        send_log_file_contents_to_console :log_file_name => @output, :file_read_options => 'r' # NUnit doesn't do funky encoding
        cleanup.call unless ENV['PRESERVE_TEMP']
      end
    end


    def get_assemblies
      override = ENV['nunit_filelist']
      file_list = override ? FileList[override] : files
      files_unique = file_list.uniq
      files_unique.join(' ')
    end

    def security_mode
      @security_mode || :normal
    end

    def executable
      arch == :any_cpu ? 'nunit-console.exe' : 'nunit-console-x86.exe'
    end

    def arch
      @arch || :any_cpu
    end

    def xml_output_flat
      xml_output == :disabled ? '/noxml' : nil
    end

    def xml_output
      @xml_output || :disabled
    end

    def output
      @output ? "/output=#{@output}" : nil
    end

    def errors
      @errors ? "/err=#{@errors}" : nil
    end

    def version
      @version || '2.6.3'
    end

    def labels
      @labels || :include_labels
    end

    def labels_flat
      labels == :include_labels ? '/labels' : nil
    end

    def testsparam
      return nil unless @tests
      @tests.is_a?(Array) ? @tests.join(',') : @tests
    end

    def framework_version
      convertToNumber(@framework_version || :v4_5)
    end

    def full_path
      dirs_under_program_files = ["NUnit #{version}", "NUnit-#{version}"]
      full_dirs_under_program_files = dirs_under_program_files.map { |d| File.join(PROGRAM_FILES_DIR, d, 'bin') }
      possibleDirectories = @base_path ? [@base_path] : full_dirs_under_program_files
      candidates = possibleDirectories.map { |p| File.join(p, executable) }
      found = candidates.detect { |c| File.exists? c }
      return found if found
      raise "We checked the following locations and could not find nunit-console.exe #{candidates}"
    end

    def timeout
      @timeout || 35000
    end
  end
end
