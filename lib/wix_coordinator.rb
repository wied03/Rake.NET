require 'basetask'
require 'msbuild'
require 'paraffin/fragment_updater'
require 'dot_net_installer'

module BradyW
  class WixCoordinator < BaseTask
    # TODO: Task 3: WIX task (calls msbuild task and task #3 using config and /p:ProductVersion=1.0.0.0 /p:UpgradeCode=6c6bbe03-e405-4e6e-84ac-c5ef16f243e7)

    # *Required* Product version to configure in the WIX/MSBUild + DotNetInstaller
    attr_accessor :product_version

    # *Required* The directory containing your .wixproj file
    attr_accessor :wix_project_directory

    # *Required* Upgrade code that is passed on to WIX and dotnetinstaller
    attr_accessor :upgrade_code

    # *Required* Fragment file that will be updated with Paraffin before calling MSBuild
    attr_accessor :paraffin_update_fragment

    # *Required* Location of the DotNetInstaller XML config file
    attr_accessor :dnetinstaller_xml_config

    # *Required* The name of the output file you want
    attr_accessor :dnetinstaller_output_exe

    # *Optional* Properties to be used with MSBuild and DotNetInstaller
    attr_accessor :properties

    # *Optional* Debug or Release.  By default true is used
    attr_accessor :release_mode

    # *Optional* A lambda to do additional configuration on the MSBuild task (e.g. dotnet_bin_version)
    attr_accessor :msbuild_configure

    def initialize(parameters = :task)
      @release_mode ||= true
      parseParams parameters
      # Need our parameters to instantiate the dependent tasks
      yield self if block_given?
      paraffin = Paraffin::FragmentUpdater.new "paraffin_#{@name}" do |pf|
        pf.fragment_file = @paraffin_update_fragment
      end

      msb = BradyW::MSBuild.new "wixmsbld_#{@name}" do |m|
        m.release = @release_mode
        m.solution = @wix_project_directory
        m.properties = @properties
        @msbuild_configure.call(m) if @msbuild_configure
      end

      dnet_inst = BradyW::DotNetInstaller.new "dnetinst_#{@name}" do |inst|
        inst.xml_config = @dnetinstaller_xml_config
        tokens = {:Configuration => @release_mode ? :Release : :Debug}
        tokens = @properties.merge tokens if @properties
        inst.tokens = tokens
        inst.output = @dnetinstaller_output_exe
      end

      @dependencies = [paraffin.name,
                       msb.name,
                       dnet_inst.name]
      # Specifying our own dependencies
      super(@name)
    end
  end
end