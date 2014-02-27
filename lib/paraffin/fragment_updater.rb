require 'basetask'
require 'path_fetcher'
require 'param_quotes'

module BradyW
  module Paraffin
    class FragmentUpdater < BaseTask
      include BradyW::ParamQuotes

      # *Required* The path to the WXS file to update
      attr_accessor :fragment_file

      # *Optional* Default is true.  If set to true, the original wxs file will be replaced with Paraffin's file.  If set to false, file will not be replaced and build will fail (using Paraffin's ReportIfDifferent flag) if there is a difference in the files
      attr_accessor :replace_original

      # *Required* The directory that should be used to update files against
      attr_accessor :output_directory

      TEMP_SYMLINK_DIR = 'paraffin_config_aware_symlink'

      def exectask
        validate
        params = ['-update',
                  quoted(@fragment_file),
                  '-verbose',
                  report_if_different]
        params.reject! { |p| !p || p.empty? }
        begin
          shell sym_link_create
          shell "\"#{path}\" #{params.join(' ')}" do |ok, status|
            if !ok
              fail "#{@fragment_file} has changed and you don't have :replace_original enabled.  Manually update #{@fragment_file} using #{generated_file} or enable :replace_original" unless @replace_original
              fail "Paraffin failed with status code: '#{status.exitstatus}'"
            end
          end
          if @replace_original
            log "Replacing #{@fragment_file} with #{generated_file}"
            FileUtils.mv generated_file, @fragment_file
          end
        ensure
          if @replace_original
            log "Removing generated file #{generated_file} since Paraffin failed"
            FileUtils.rm generated_file if File.exists? generated_file
          end
          shell sym_link_delete
        end
      end


      def initialize(parameters = :task)
        @replace_original = true
        super parameters
      end

      private

      def sym_link_delete
        "rmdir #{sym_link_dir}"
      end

      def sym_link_create
        scan_dir = windows_friendly_path(quoted(output_directory))
        # Mklink is not an executable, part of the shell
        "cmd.exe /c mklink /J #{sym_link_dir} #{scan_dir}"
      end

      def sym_link_dir
        dir = File.join(File.dirname(fragment_file), TEMP_SYMLINK_DIR)
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

      def report_if_different
        '-ReportIfDifferent' unless @replace_original
      end

      def path
        BswTech::DnetInstallUtil::PARAFFIN_EXE
      end
    end
  end
end