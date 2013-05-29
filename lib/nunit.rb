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

    # *Optional* Location of nunit-console.exe, defaults to C:\Program Files\NUnit-${version}\bin
    attr_accessor :path

    private

    def exectask
      assemblies = files.join(" ")
      shell "\"#{path}\\nunit-console.exe\" /framework=#{framework_version} #{assemblies}"
    end

    def version
      @version || "2.6.2"
    end

    def framework_version
      convertToNumber(@framework_version || :v4_5)
    end

    def path
      @path || "C:\\Program Files (x86)\\NUnit-#{version}\\bin"
    end


  end
end