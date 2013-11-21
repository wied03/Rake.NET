require 'basetask'
require 'path_fetcher'
require 'param_quotes'

module BradyW
  module Paraffin
    class FragmentGenerator < BaseTask
      include ParamQuotes

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

      # *Optional* Should the root directory be ignored?
      attr_accessor :no_root_directory

      # *Optional* File extensions (don't include a dot or any wildcards) that should be ignored. Can be an array or single item
      attr_accessor :ignore_extensions

      # *Optional* Regular expressions that should be ignored. Can be an array or single item
      attr_accessor :exclude_regexp

      def exectask
        validate
        params = [directory_to_scan,
                  directory_reference,
                  component_group,
                  @output_file,
                  the_alias,
                  ignore_extensions,
                  exclude_regexp,
                  '-verbose',
                  no_root_directory]
        params.reject! &:empty?
        flat_params = params.join ' '
        shell "\"#{path}\" #{flat_params}"
      end

      private

      def validate
        required = {:component_group => @component_group,
                    :alias => @alias,
                    :output_file => @output_file,
                    :directory_to_scan => @directory_to_scan}
        missing = required.reject { |k, v| v }
        .keys
        fail "These required attributes must be set by your task: #{missing}" unless missing.empty?
      end

      def exclude_regexp
        [*@exclude_regexp].map { |re| switch_and_param 'regExExclude', re, :quote => true }
      end

      def ignore_extensions
        [*@ignore_extensions].map { |ext| switch_and_param 'ext', ext }
      end

      def no_root_directory
        @no_root_directory ? "-NoRootDirectory" : String.new
      end

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

      def path
        BswTech::DnetInstallUtil::PARAFFIN_EXE
      end
    end
  end
end