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
      params = [param_fslash('service', @service_to_grant_access_to),
                param_fslash_eq('grant', "#{@user_to_grant_top_access_to}=top")]
      shell "#{elevate_and_exe_path} #{params.join(' ')}"
    end

    private
    def elevate_and_exe_path
      "#{BswTech::DnetInstallUtil::ELEVATE_EXE} -w \"#{subinacl_path}\""
    end
  end
end