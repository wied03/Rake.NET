require 'basetask'
require 'path_fetcher'

module BradyW
  class ParaffinFragmentGenerator < BaseTask
    # *Optional* Which directory reference (defined somewhere in your wxs files) should be used
    attr_accessor :directory_reference

    # *Required* The component group used for generated files
    attr_accessor :component_group

    # *Required* Which project reference alias will be used on the paths (e.g. $(var...))
    attr_accessor :alias

    # *Required* What WXS file path do you want Paraffin to generate?
    attr_accessor :output_file

    # *Required* Which directory should be scanned?
    attr_accessor :directory_to_scan

    def exectask
      shell "\"#{path}\"#{directory_to_scan}#{directory_reference}#{component_group} #{@output_file}#{the_alias} -verbose"
    end

    private

    def the_alias
      switch_and_param 'alias', @alias
    end

    def component_group
      switch_and_param 'GroupName', @component_group
    end

    def directory_to_scan
      switch_and_param 'dir', @directory_to_scan, :quote => true
    end

    def directory_reference
      switch_and_param 'dr', @directory_reference
    end


    def switch_and_param(switch,setting,options=nil)
      return "" if ! setting
      quoteSetting = options.is_a?(Hash) && options[:quote]
      quoted = quoteSetting ? quoted(setting) : setting
      " -#{switch} #{quoted}"
    end

    def quoted(setting)
          "\"#{setting}\""
    end


    def path
      BswTech::DnetInstallUtil::PARAFFIN_EXE
    end
  end
end