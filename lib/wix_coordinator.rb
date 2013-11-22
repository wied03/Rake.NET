require 'basetask'
require 'msbuild'

module BradyW
  class WixCoordinator < BaseTask
    # TODO: Task 3: WIX task (calls msbuild task and task #3 using config and /p:ProductVersion=1.0.0.0 /p:UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7)

    # *Required* Product version to configure in the WIX/MSBUild + DotNetInstaller
    attr_accessor :product_version

    # *Required* Upgrade code that is passed on to WIX and dotnetinstaller
    attr_accessor :upgrade_code

    # *Required* Fragment file that will be updated with Paraffin before calling MSBuild
    attr_accessor :paraffin_update_fragment

    # *Required* Location of the DotNetInstaller XML config file
    attr_accessor :dnetinstaller_xml_config

    # *Required* The name of the output file you want
    attr_accessor :dnetinstaller_output_exe

    def initialize(parameters = :task)
      parseParams parameters
      BradyW::MSBuild.new "wix_msbuild" do |msb|
        msb.release = true
      end

      @dependencies = ["wix_msbuild"]
      # Specifying our own dependencies
      super(@name)
    end
  end
end