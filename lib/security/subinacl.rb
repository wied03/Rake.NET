require 'basetask'
require 'windowspaths'
require 'path_fetcher'
require 'param_quotes'
require 'temp_file_name_generator'

module BradyW
  class Subinacl < BaseTask
    include WindowsPaths
    include ParamQuotes

    attr_accessor :service_to_grant_access_to
    attr_accessor :user_to_grant_top_access_to

    def exectask
      raise 'Subinacl not found on your system.  Did you install MSI version 5.2.3790 ?' if !subinacl_path
      params = [param_fslash('service', @service_to_grant_access_to),
                param_fslash_eq('grant', "#{@user_to_grant_top_access_to}=top")]
      temp_batch_file_name = BradyW::TempFileNameGenerator.random_filename 'run_subinacl_with_output_redirect', '.bat'
      log_file_name = BradyW::TempFileNameGenerator.random_filename 'subinacl_log', '.txt'
      # Need to use binary mode to avoid CRLF/Windows issues since it's picky about batch files
      File.open temp_batch_file_name, 'wb' do |file|
        file << exe_path_with_redirection(params,log_file_name)
      end

      log_file_already_written = false

      begin
        full_path = File.expand_path temp_batch_file_name
        shell "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w #{quoted(windows_friendly_path(full_path))}"
        error_count_regex = /Done:\s+\d+, Modified\s+\d+, Failed\s+(\d+), Syntax errors\s+(\d+)/
        error_object_regex = /Current object \w+ will not be processed/
        failed = false
        write_log_to_console log_file_name do |line_being_logged|
          match = error_count_regex.match(line_being_logged)
          if match
            captures = match.captures
            failures = captures[0].to_i
            syntax_errors = captures[1].to_i
            failed = true if failures > 0 or syntax_errors > 0
          end
          failed = true if error_object_regex.match(line_being_logged)
        end
        log_file_already_written = true
        raise 'Subinacl failed due to syntax errors or failures in making the requested change' if failed
      ensure
        # Elevated subinacl runs in a separate window and we won't see its output in the build script
        write_log_to_console log_file_name unless log_file_already_written
        FileUtils.rm log_file_name unless preserve_temp_files
        FileUtils.rm temp_batch_file_name unless preserve_temp_files
      end
    end

    private

    def write_log_to_console(filename)
      send_log_file_contents_to_console(:log_file_name => filename) do |line|
        yield line
      end
    end

    def exe_path_with_redirection(params,log_file_name)
      path = quoted(windows_friendly_path(File.expand_path(log_file_name)))
      "\"#{subinacl_path}\" #{params.join(' ')} 1> #{path} 2>&1"
    end
  end
end