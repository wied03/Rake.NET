require 'basetask'
require 'path_fetcher'

module BradyW
  class ParaffinFragmentUpdater < BaseTask

    # *Required* The path to the WXS file to update
    attr_accessor :fragment_file

    def exectask
      if !@fragment_file
        raise ":fragment_file is required for this task"
      end

      params = ['-update',@fragment_file,'-verbose']
      shell "\"#{path}\" #{params.join(' ')}"
    end

    private

    def path
      BswTech::DnetInstallUtil::PARAFFIN_EXE
    end
  end
end