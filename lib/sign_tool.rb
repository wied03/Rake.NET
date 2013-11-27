require 'basetask'
require 'windowspaths'
require 'param_quotes'

module BradyW
  class SignTool < BaseTask
    include WindowsPaths
    include ParamQuotes

    # *Required* The subject of the certificate in your certificate store to use for signing
    attr_accessor :subject

    # *Required* Description of what is being signed
    attr_accessor :description

    # *Required* What to sign
    attr_accessor :sign_this

    # *Optional* What timestamp URL to use for signing (by default will be http://timestamp.verisign.com/scripts/timestamp.dll)
    attr_accessor :timestamp_url

    # *Optional* Architecture of signtool.exe to use (either :x86 or :x64). :x64 by default
    attr_accessor :architecture

    def exectask
      validate
      params = ['sign',
                param_fslash('n', @subject, :quote => true),
                param_fslash('t', timestamp_url),
                param_fslash('d', @description, :quote => true),
                quoted(@sign_this)]
      shell "#{quoted(path)} #{params.join(' ')}"
    end

    private

    def validate
       fail ':subject, :description, and :sign_this are required' unless @subject && @description && @sign_this
    end

    def path
      signtool_exe architecture
    end

    def timestamp_url
      @timestamp_url || 'http://timestamp.verisign.com/scripts/timestamp.dll'
    end

    def architecture
      @architecture || :x64
    end
  end
end