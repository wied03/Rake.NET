require 'basetask'

class DotNetInstaller

  # TODO: Use the .net installer module as a default path for these tools
  # TODO: Task 1: Paraffin executor (arrays for ext and the directory exclude)
  # TODO: Task 3: WIX task (calls msbuild task and task #3 using config and /p:ProductVersion=1.0.0.0 /p:UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7)
  # TODO: Task 2: DotNetinstaller task.  should do token replace in XML,make a temp copy, then call something like this: "%DNET_INSTALLER_PATH%\InstallerLinker.exe" /c:dotnetinstaller.xml /o:bin\Release\Bsw.Coworking.Agent.Installer.exe /t:"%DNET_INSTALLER_PATH%\dotNetInstaller.exe"
end