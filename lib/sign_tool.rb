require 'basetask'
require 'param_quotes'
require 'registry_accessor'

module BradyW
  class SignTool < BaseTask
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

    # *Optional* Version of the SDK to use signtool from, defaults to latest version on your machine
    attr_accessor :sdk_version

    def initialize(parameters = :task)
      @registry = BradyW::RegistryAccessor.new
      super
    end

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

    def timestamp_url
      @timestamp_url || 'http://timestamp.verisign.com/scripts/timestamp.dll'
    end

    def architecture
      @architecture || :x64
    end

    def sdk_version
      @sdk_version ? "v#{@sdk_version}" : latest_sdk_version
    end

    def latest_sdk_version
      versions = @registry.get_sub_keys 'SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows'
      numbers_only = versions.map { |i|
        match = /v(\d+\.{0,1}\d+)(?!\w)/.match(i)
        match ? match[1] : nil
      }.uniq
      numbers_only.reject! {|item| !item}
      latest_version = numbers_only.max
      "v#{latest_version}"
    end

    def path
      base_path = @registry.get_value "SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\#{sdk_version}", 'InstallationFolder'
      File.join base_path,
                'bin',
                architecture.to_s,
                'signtool.exe'
    end
  end
end