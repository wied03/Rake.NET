require_relative '../basetask'
require_relative '../binary_locator/windowspaths'
require_relative '../util/dot_net_version_symbol_to_number_converter'
require_relative '../util/param_quotes'

module BradyW

  # Launches a build using MSBuild
  class MSBuild < BaseTask
    include WindowsPaths
    include DotNetVersionSymbolToNumberConverter
    include ParamQuotes

    # *Optional* Targets to build.  Can be a single target or an array of targets
    attr_accessor :targets

    # *Optional* Which MSBuild version to use. By default, will use latest version installed (typically in C:\Program Files (x86)\MSBuild\14.0\Bin)
    # If you supply a Float (e.g. 14.0, 13.0), then that MSBuild version will be used. If you supply a string, then that absolute path will be used
    attr_accessor :path

    # *Optional* Solution file to build
    attr_accessor :solution

    # *Optional* .NET compilation version (what should MSBuild compile code to, NOT what version
    # of MSBuild to use).  Defaults to :v4_5).  Other options are :v2_0, :v3_5, :v4_0
    attr_accessor :compile_version

    # *Optional* Properties to pass along to MSBuild.  By default 'Configuration' and
    # 'TargetFrameworkVersion' will be set based on the other attributes of this class.
    attr_accessor :properties

    # *Optional* :Release or :Debug build, :Debug by default
    attr_accessor :build_config


    def initialize (parameters = :task)
      super parameters
      @build_config ||= :Debug
      @registry_accessor = BradyW::RegistryAccessor.new
    end

    private

    def exectask
      params = targets
      params << merged_properties.map { |key, val| param_fslash_colon('property', property_kv(key, val)) }
      params_flat = params.join ' '
      command = quoted_for_spaces File.join(path, 'MSBuild.exe')
      shell "#{command} #{params_flat}#{solution}"
    end

    def compile_version
      symbol = @compile_version || :v4_5
      ver = convertToNumber symbol
      "v#{ver}"
    end

    def solution
      " #{@solution}" if @solution
    end

    def targets
      @targets ? [*@targets].map { |t| param_fslash_colon 'target', t } : []
    end

    def property_kv(key, value)
      "#{key}=#{handle_property_quotes(value)}"
    end

    def handle_property_quotes(val)
      val_str = val.to_s
      val_str.match(/[\s;]/) ? quoted(val_str) : val_str
    end

    def merged_properties
      default = {:Configuration => build_config,
                 :TargetFrameworkVersion => compile_version}
      default.merge (@properties || {})
    end

    def get_msbuild_path(version)
      @registry_accessor.get_value "SOFTWARE\\Microsoft\\MSBuild\\ToolsVersions\\#{version}", 'MsBuildToolsPath'
    end

    def path
      get_msbuild_path '14.0'
    end
  end
end
