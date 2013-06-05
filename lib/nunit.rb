require 'basetask'
require 'dotframeworksymbolhelp'

module BradyW
  class Nunit < BaseTask
    include Dotframeworksymbolhelp

    # *Required* Files/assemblies to test
    attr_accessor :files

    # *Optional* Version of NUnit in use, defaults to 2.6.2
    attr_accessor :version

    # *Optional* What version of the .NET framework to use for the tests?  :v2_0, :v3_5, :v4_0, :v4_5, defaults to :v4_5
    attr_accessor :framework_version

    # *Optional* Location of nunit-console.exe, defaults to C:\Program Files (x86)\NUnit ${version}\bin
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

    private

    def exectask
      assemblies = files.join(" ")
      shell "\"#{path}\\nunit-console.exe\"#{output}#{errors}#{labels_flat}#{xml_output_flat}/framework=#{framework_version} /timeout=#{timeout}#{testsparam}#{assemblies}"
    end

    def xml_output_flat
      xml_output == :disabled ? " /noxml " : " "
    end

    def xml_output
      @xml_output || :disabled
    end

    def output
      @output ? " /output=#{@output}" : ""
    end

    def errors
      @errors ? " /err=#{@errors}" : ""
    end

    def version
      @version || "2.6.2"
    end

    def labels
      @labels || :include_labels
    end

    def labels_flat
      labels == :include_labels ? " /labels" : ""
    end

    def testsparam
      return " " unless @tests
      flat = @tests.is_a?(Array) ? @tests.join(",") : @tests
      " /run=#{flat} "
    end

    def framework_version
      convertToNumber(@framework_version || :v4_5)
    end

    def path
      @path || "C:\\Program Files (x86)\\NUnit #{version}\\bin"
    end

    def timeout
      @timeout || 35000
    end
  end
end