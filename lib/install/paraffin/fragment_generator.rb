require_relative '../../basetask'
require_relative '../../util/param_quotes'

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

      # *Optional* Directories that will be excluded.  Any relative path given will be considered relative to :directory_to_scan.  Can either be array or single item
      attr_accessor :directories_to_exclude

      TEMP_SYMLINK_DIR = 'paraffin_config_aware_symlink'

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
        params.reject! { |p| !p || p.empty? }
        flat_params = params.join ' '
        # Reason we create the symlink is so that we can scan "someProj/Debug" but on the fly and later do an update based on the config
        # we are building with (e.g. Release) and not have Debug hard coded in the Paraffin XML
        shell sym_link_create
        begin
          shell "\"#{path}\" #{flat_params}"
        ensure
          # Need to use Windows directly since this is a "symlink"
          shell sym_link_delete
        end
      end

      private

      def regular_expressions
        [*@exclude_regexp] + exclude_directory_regexes
      end

      def exclude_directory_regexes
        [*@directories_to_exclude].map { |dir| turn_directory_into_regex(dir) }
      end

      # Exclude directories is deprecated according to Paraffin documentation
      def turn_directory_into_regex(dir)
        is_absolute = File.absolute_path(dir) == dir
        prefixed = is_absolute ? dir : File.join(sym_link_dir_not_win_friendly, dir)
        win_friendly = windows_friendly_path prefixed
        Regexp.escape win_friendly
      end

      def sym_link_delete
        "rmdir #{sym_link_dir_absolute}"
      end

      def sym_link_create
        # Mklink needs an absolute path
        scan_dir = windows_friendly_path(quoted(File.absolute_path(@directory_to_scan)))
        # Mklink is not an executable, part of the shell
        "cmd.exe /c mklink /J #{sym_link_dir_absolute} #{scan_dir}"
      end

      def sym_link_dir_absolute
        dir = File.absolute_path(sym_link_dir_not_win_friendly)
        quoted(windows_friendly_path(dir))
      end

      def sym_link_dir_not_win_friendly
        File.join(File.dirname(@output_file), TEMP_SYMLINK_DIR)
      end

      def sym_link_dir
        dir = sym_link_dir_not_win_friendly
        quoted(windows_friendly_path(dir))
      end

      def validate
        required = {:component_group => @component_group,
                    :alias => @alias,
                    :output_file => @output_file,
                    :directory_to_scan => @directory_to_scan}
        missing = required.reject { |k, v| v }.keys
        fail "These required attributes must be set by your task: #{missing}" unless missing.empty?
      end

      def exclude_regexp
        regular_expressions.map { |re| switch_and_param 'regExExclude', re, :quote => true }
      end

      def ignore_extensions
        [*@ignore_extensions].map { |ext| switch_and_param 'ext', ext }
      end

      def no_root_directory
        '-NoRootDirectory' if @no_root_directory
      end

      def the_alias
        switch_and_param 'alias', @alias
      end

      def component_group
        switch_and_param 'GroupName', @component_group
      end

      def directory_to_scan
        switch_and_param 'dir', sym_link_dir
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