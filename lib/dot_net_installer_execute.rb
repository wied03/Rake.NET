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
      params = ["/#{mode_switch}"]
      params << param_fslash('ComponentArgs', properties_flat) if @mode == :install
      params << '/q'
      params_flat = params.join ' '
      shell "#{path} #{params_flat}"
    end

    private

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