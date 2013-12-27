require 'basetask'
require 'param_quotes'

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
      raise 'implement this'
    end
  end
end