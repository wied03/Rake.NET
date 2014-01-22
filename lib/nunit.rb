require 'basetask'
require 'dotframeworksymbolhelp'
require 'param_quotes'
require 'path_fetcher'
require 'temp_file_name_generator'

module BradyW
  class Nunit < BaseTask
    include Dotframeworksymbolhelp
    include ParamQuotes
    PROGRAM_FILES_DIR = "C:/Program Files (x86)"

    # *Required* Files/assemblies to test.  You can also override this each time by setting the environment variable 'nunit_filelist' to a glob pattern
    attr_accessor :files

    # *Optional* Version of NUnit in use, defaults to 2.6.3
    attr_accessor :version

    # *Optional* What version of the .NET framework to use for the tests?  :v2_0, :v3_5, :v4_0, :v4_5, defaults to :v4_5
    attr_accessor :framework_version

    # *Optional* Full path of nunit-console.exe, defaults to C:\Program Files (x86)\NUnit ${version}\bin\nunit-console.exe
    attr_accessor :path

    # *Optional* Timeout for each test case in milliseconds, by default the timeout is 35 seconds
    attr_accessor :timeout

    # *Optional* Which tests should be run (specify namespace+class), can be multiple, defaults to all in class
    attr_accessor :tests

    # *Optional* Should XML be outputted?  By default the answer is no, but set this to :enabled if you want XML output
    attr_accessor :xml_output

    # *Optional* Should labels be printed in the test output, default is :include_labels, can also say :exclude_labels
    attr_accessor :labels

    # *Optional* Where should test output be stored?  Default is console
    attr_accessor :output

    # *Optional* Where should test errors be stored?  Default is console
    attr_accessor :errors

    # *Optional* Should :x86 or :anycpu archiecture be used?  Default is :anycpu
    attr_accessor :arch

    # *Optional* :elevated or :normal, :normal by default.  if :elevated, XML output will be enabled
    attr_accessor :security_mode

    private

    def exectask
      override = ENV['nunit_filelist']
      file_list = override ? FileList[override] : files
      assemblies = file_list.uniq.join(' ')
      # Elevated NUnit runs in a separate window and we won't see its output in the build script
      if security_mode == :elevated
        @xml_output = :enabled
        temp_file = TempFileNameGenerator.random_filename('nunitoutput','txt') unless @output
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
      params << assemblies
      params.reject! { |p| !p || p.empty? }
      path_based_on_mode = security_mode == :elevated ? elevate_and_exe_path : "\"#{full_path}\""
      shell "#{path_based_on_mode} #{params.join(' ')}"
      # Elevated NUnit runs in a separate window and we won't see its output in the build script
      if security_mode == :elevated
        log get_file_contents(@output)
        FileUtils.rm @output if temp_file
      end
    end

    def get_file_contents(src_file_name)
      text = ''
      File.open src_file_name, 'r' do |input|
        input.each do |line|
          text << line
        end
      end
      text
    end

    def security_mode
      @security_mode || :normal
    end

    def executable
      arch == :any_cpu ? 'nunit-console.exe' : 'nunit-console-x86.exe'
    end

    def elevate_and_exe_path
      # Elevate.exe needs windows style backslash path here and needs to wait for elevation to complete
      exe_path = full_path.gsub(/\//, '\\')
      "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"#{exe_path}\""
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
      possibleDirectories = ["NUnit #{version}", "NUnit-#{version}"]
      candidates = @path ? [@path] : possibleDirectories.map { |p| File.join(PROGRAM_FILES_DIR, p, "bin", executable) }
      found = candidates.detect { |c| File.exists? c }
      return found if found
      raise "We checked the following locations and could not find nunit-console.exe #{candidates}"
    end

    def timeout
      @timeout || 35000
    end
  end
end