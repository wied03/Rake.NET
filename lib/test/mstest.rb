require_relative '../basetask'

module BradyW
  # Runs MSTest tests using Visual Studio's MSTest runner
  class MSTest < BaseTask
    include BradyW::WindowsPaths

    # *Required* Files/test containers to test
    attr_accessor :files

    # *Optional* Version of Visual Studio/MSTest to use, defaults to 10.0
    attr_accessor :version

    private

    def exectask
      shell "\"#{path}MSTest.exe\"#{testcontainers}"
    end

    def testcontainers
      specifier = " /testcontainer:"
      mainstr = files.join(specifier)
      specifier+mainstr
    end

    def path
      visual_studio version
    end

    def version
      @version || "10.0"
    end
  end
end