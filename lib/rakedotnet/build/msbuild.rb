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
    # If you supply a Float (e.g. 14.0, 13.0), then that MSBuild version will be used. If you supply a string, then that absolute path will be used. String should include the .exe
    attr_accessor :path

    # *Optional* Solution file to build
    attr_accessor :solution

    # *Optional* .NET compilation version (what should MSBuild compile code to, NOT what version
    # of MSBuild to use).  Default is to let MSBuild handle it. If you supply a value, needs to be a Float
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
      @resolved_path = get_path
      @resolved_compile = get_compile_version
    end

    private

    def exectask
      params = targets
      params << merged_properties.map { |key, val| param_fslash_colon('property', property_kv(key, val)) }
      params_flat = params.join ' '
      shell "#{@resolved_path} #{params_flat}#{solution}"
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
      default = {Configuration: build_config}
      default[:TargetFrameworkVersion] = @resolved_compile if @resolved_compile
      default.merge (@properties || {})
    end

    def get_msbuild_path(version)
      @registry_accessor.get_value "SOFTWARE\\Microsoft\\MSBuild\\ToolsVersions\\#{version}", 'MsBuildToolsPath'
    end

    def get_msbuild_versions
      @registry_accessor.get_sub_keys('SOFTWARE\\Microsoft\\MSBuild\\ToolsVersions').map { |v| v.to_f }
    end

    def get_path
      all_versions = get_msbuild_versions.sort.reverse
      version_to_use = if @path and (path_as_number = @path.to_f) and path_as_number != 0.0
                         raise "You requested version #{path_as_number} but that version is not installed. Installed versions are #{all_versions}" unless all_versions.include?(path_as_number)
                         path_as_number
                       elsif @path
                         raise "You requested to use #{@path} but that file does not exist!" unless File.exist?(@path)
                         @path
                       else
                         all_versions.first
                       end

      resolved = if version_to_use.is_a?(String)
                   version_to_use
                 else
                   containing_dir = get_msbuild_path version_to_use
                   File.join(containing_dir, 'MSBuild.exe')
                 end
      quoted_for_spaces resolved
    end

    def get_compile_version
      if @compile_version and (as_number = @compile_version.to_f) and as_number != 0.0
        "v#{as_number}"
      elsif @compile_version
        raise "Compile version needs to be convertible to float and '#{@compile_version}' is not"
      else
        nil
      end
    end
  end
end
