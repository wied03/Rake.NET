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

      def exectask
        validate
        params = ['-update',
                  quoted(@fragment_file),
                  '-verbose',
                  report_if_different]
        params.reject!{|p| !p || p.empty?}
        base_path = File.dirname @fragment_file
        file_name = File.basename @fragment_file
        generated_file = File.join base_path, "#{file_name}.PARAFFIN"
        shell "\"#{path}\" #{params.join(' ')}" do |ok, status|
          if !ok
            raise "#{@fragment_file} has changed and you don't have :replace_original enabled.  Manually update #{@fragment_file} using #{generated_file} or enable :replace_original" unless @replace_original

            if @replace_original
              log "Removing generated file #{generated_file} since Paraffin failed"
              FileUtils.rm generated_file
            end

            fail "Paraffin failed with status code: '#{status.exitstatus}'"
          end
        end
        if @replace_original
          log "Replacing #{@fragment_file} with #{generated_file}"
          FileUtils.mv generated_file, @fragment_file
        end
      end


      def initialize(parameters = :task)
        @replace_original = true
        super parameters
      end

      private

      def validate
        fail ":fragment_file is required for this task" unless @fragment_file
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