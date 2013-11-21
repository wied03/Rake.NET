require 'basetask'
require 'path_fetcher'
require 'date'

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

    # TODO: Use the .net installer module as a default path for these tools
    # TODO: Task 3: WIX task (calls msbuild task and task #3 using config and /p:ProductVersion=1.0.0.0 /p:UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7)
    # TODO: Task 2: DotNetinstaller task.  should do token replace in XML,make a temp copy, then call something like this: "%DNET_INSTALLER_PATH%\InstallerLinker.exe" /c:dotnetinstaller.xml /o:bin\Release\Bsw.Coworking.Agent.Installer.exe /t:"%DNET_INSTALLER_PATH%\dotNetInstaller.exe"
  end
end