require 'basetask'
require 'msbuild'
require 'paraffin/fragment_updater'
require 'dot_net_installer'

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
      paraffin = Paraffin::FragmentUpdater.new "paraffin_#{@name}" do |pf|
      end

      msb = BradyW::MSBuild.new "wixmsbld_#{@name}" do |msb|
        msb.release = true
      end

      dnet_inst = BradyW::DotNetInstaller.new "dnetinst_#{@name}" do |inst|

      end

      @dependencies = [paraffin.name,
                       msb.name,
                       dnet_inst.name]
      # Specifying our own dependencies
      super(@name)
    end
  end
end