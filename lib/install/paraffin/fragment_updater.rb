require_relative '../../basetask'
require_relative '../../util/param_quotes'
require_relative '../../binary_locator/windowspaths'

module BradyW
  module Paraffin
    class FragmentUpdater < BaseTask
      include BradyW::ParamQuotes
      include BradyW::WindowsPaths

      # *Required* The path to the WXS file to update
      attr_accessor :fragment_file

      # *Required* The directory that should be used to update files against
      attr_accessor :output_directory

      TEMP_SYMLINK_DIR = 'paraffin_config_aware_symlink'

      def exectask
        validate
        params = ['-update',
                  quoted(@fragment_file),
                  '-verbose',
                  '-ReportIfDifferent']
        params.reject! { |p| !p || p.empty? }
        begin
          shell sym_link_create
          shell "\"#{path}\" #{params.join(' ')}" do |ok, status|
            if !ok
              code = status.exitstatus
              fail "#{@fragment_file} has changed.  Review updates to #{@fragment_file} manually and rebuild" if code == 4
              fail "Paraffin failed with status code: '#{code}'"
            end
          end
        ensure
          if File.exist? generated_file
            log "Replacing #{@fragment_file} with #{generated_file}"
            FileUtils.mv generated_file, @fragment_file
          else
            log "Will not replace #{@fragment_file} with #{generated_file} because Paraffin didn't generate it"
          end
          shell sym_link_delete
        end
      end


      def initialize(parameters = :task)
        super parameters
      end

      private

      def sym_link_delete
        "rmdir #{sym_link_dir_absolute}"
      end

      def sym_link_create
        # Mklink needs an absolute path
        scan_dir = windows_friendly_path(quoted(File.absolute_path(output_directory)))
        # Mklink is not an executable, part of the shell
        "#{cmd_exe} /c mklink /J #{sym_link_dir_absolute} #{scan_dir}"
      end

      def sym_link_dir_absolute
        dir = File.absolute_path(sym_link_dir_not_win_friendly)
        quoted(windows_friendly_path(dir))
      end

      def sym_link_dir_not_win_friendly
        File.join(File.dirname(fragment_file), TEMP_SYMLINK_DIR)
      end

      def sym_link_dir
        dir = sym_link_dir_not_win_friendly
        quoted(windows_friendly_path(dir))
      end

      def generated_file
        ext = File.extname file_name_only
        without_ext = file_name_only.sub "#{ext}", ''
        File.join base_path, "#{without_ext}.PARAFFIN"
      end

      def file_name_only
        File.basename @fragment_file
      end

      def base_path
        File.dirname @fragment_file
      end

      def validate
        fail ":fragment_file and :output_directory are required for this task" unless (@fragment_file && @output_directory)
      end

      def path
        BswTech::DnetInstallUtil::PARAFFIN_EXE
      end
    end
  end
end