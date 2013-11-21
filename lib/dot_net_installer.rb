require 'basetask'
require 'path_fetcher'
require 'date'
require 'param_quotes'

module BradyW
  class TempXmlFileNameGenerator
    def self.filename(originalFileName)
      dir = File.dirname originalFileName
      filename = File.basename originalFileName
      ext = File.extname filename
      withoutExt = filename.sub "#{ext}", ''
      tempFileName = "#{withoutExt}_#{DateTime.now.strftime('%s')}#{ext}"
      File.join dir, tempFileName
    end
  end

  class DotNetInstaller < BaseTask
    include ParamQuotes

    # TODO: Use the .net installer module as a default path for these tools
    # TODO: Task 3: WIX task (calls msbuild task and task #3 using config and /p:ProductVersion=1.0.0.0 /p:UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7)
    # TODO: Task 2: DotNetinstaller task.  should do token replace in XML,make a temp copy, then call something like this: "%DNET_INSTALLER_PATH%\InstallerLinker.exe" /c:dotnetinstaller.xml /o:bin\Release\Bsw.Coworking.Agent.Installer.exe /t:"%DNET_INSTALLER_PATH%\dotNetInstaller.exe"

    # *Required* The XML file generated by the dotNetInstaller editor
    attr_accessor :xml_config

    # *Required* The full path of the output EXE you want generated
    attr_accessor :output

    # *Optional* Tokens to replace in the XML file before calling dotNetInstaller.  Use $(tokenName) syntax in your XML
    attr_accessor :tokens

    def exectask
      generated_file_name = TempXmlFileNameGenerator.filename @xml_config
      File.open(generated_file_name,'w') do |out|
        File.open @xml_config, 'r' do |input|
          input.each do |line|
            if @tokens then
              @tokens.each do |k,v|
                line.sub! token_replace(k), v
              end
            end
            out << line
          end
        end
      end
      params=[param('c', generated_file_name, :quote => true),
              param('o', @output, :quote => true),
              param('t', bootstrapper_path, :quote => true)]
      shell "\"#{linker_path}\" #{params.join(' ')}" do |ok, status|

      end
    end

    def param(switch, setting, options={})
      return String.new if !setting
      quoted = options[:quote] ? quoted(setting) : setting
      "/#{switch}:#{quoted}"
    end

    private

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