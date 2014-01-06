require 'basetask'
require 'path_fetcher'
require 'date'
require 'param_quotes'
require 'temp_file_name_generator'

module BradyW
  class DotNetInstaller < BaseTask
    include ParamQuotes

    # *Required* The XML file generated by the dotNetInstaller editor
    attr_accessor :xml_config

    # *Required* The full path of the output EXE you want generated
    attr_accessor :output

    # *Optional* Tokens to replace in the XML file before calling dotNetInstaller.  Use $(tokenName) syntax in your XML
    attr_accessor :tokens

    def exectask
      validate
      generated_file_name = generate_xml_file
      params=[param_fslash_colon('c', generated_file_name, :quote => true),
              param_fslash_colon('o', @output, :quote => true),
              param_fslash_colon('t', bootstrapper_path, :quote => true)]
      clean_file = lambda { FileUtils.rm generated_file_name unless ENV['PRESERVE_TEMP'] }
      shell "\"#{linker_path}\" #{params.join(' ')}" do |ok, status|
        if !ok then
          clean_file.call
          fail "Problem with dotNetInstaller.  Return code '#{status.exitstatus}'"
        end
      end
      clean_file.call
    end

    private

    def validate
      fail ":xml_config and :output are required" if !@xml_config || !@output
    end

    def generate_xml_file
      generated_file_name = TempFileNameGenerator.filename @xml_config
      File.open(generated_file_name, 'w') do |out|
        File.open @xml_config, 'r' do |input|
          input.each do |line|
            if @tokens then
              @tokens.each do |k, v|
                line.sub! token_replace(k), v.to_s
              end
            end
            out << line
          end
        end
      end
      generated_file_name
    end

    def token_replace(token)
      "$(#{token})"
    end

    def linker_path
      File.join bin_path, 'InstallerLinker.exe'
    end

    def bootstrapper_path
      File.join bin_path, 'dotNetInstaller.exe'
    end

    def bin_path
      File.join base_path, 'Bin'
    end

    def base_path
      BswTech::DnetInstallUtil.dot_net_installer_base_path
    end
  end
end