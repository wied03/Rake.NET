module BradyW

  # Launches a build using MSBuild
  class MSBuild < BaseTask
    include WindowsPaths
    include Dotframeworksymbolhelp
    include ParamQuotes

    # *Optional* Targets to build.  Can be a single target or an array of targets
    attr_accessor :targets

    # *Optional* Version of the MSBuild binary to use. Defaults to :v4_5
    # Other options are :v2_0, :v3_5, :v4_0
    attr_accessor :dotnet_bin_version

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
    end

    private

    DOTNET4_REG_PATH = "v4\\Client"
    DOTNET35_REGPATH = "v3.5"
    DOTNET2_HARDCODEDPATH = "C:\\Windows\\Microsoft.NET\\Framework\\v2.0.50727\\"

    def exectask
      params = targets
      params << merged_properties.map { |key, val| param_fslash_colon('property', property_kv(key, val)) }
      params_flat = params.join ' '
      shell "#{path}msbuild.exe #{params_flat}#{solution}"
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

    def path
      symbol = @dotnet_bin_version || :v4_5
      case symbol
        when :v4_0
          dotnet DOTNET4_REG_PATH
        when :v4_5
          dotnet DOTNET4_REG_PATH
        when :v3_5
          dotnet DOTNET35_REGPATH
        when :v2_0
          DOTNET2_HARDCODEDPATH
        else
          fail 'You supplied a .NET MSBuild binary version that\'s not supported.  Please use :v4_0, :v3_5, or :v2_0'
      end
    end
  end
end