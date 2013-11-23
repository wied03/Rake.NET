require 'basetask'
require 'msbuild'
require 'paraffin/fragment_updater'
require 'dot_net_installer'

module BradyW
  class WixCoordinator < BaseTask
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

      validate

      paraffin = Paraffin::FragmentUpdater.new "paraffin_#{@name}" do |pf|
        pf.fragment_file = paraffin_update_fragment
      end

      msb = BradyW::MSBuild.new "wixmsbld_#{@name}" do |m|
        m.release = @release_mode
        m.solution = @wix_project_directory
        m.properties = properties
        @msbuild_configure.call(m) if @msbuild_configure
      end

      dnet_inst = BradyW::DotNetInstaller.new "dnetinst_#{@name}" do |inst|
        inst.xml_config = dnetinstaller_xml_config
        tokens = {:Configuration => configuration}
        tokens = properties.merge tokens
        inst.tokens = tokens
        inst.output = dnetinstaller_output_exe
      end

      @dependencies = [*@dependencies] + [paraffin.name,
                                          msb.name,
                                          dnet_inst.name]
      # Specifying our own dependencies
      super(@name)
    end

    def exectask
      # We're just a task of dependencies
    end

    private

    def configuration
      @release_mode ? :Release : :Debug
    end

    def dnetinstaller_output_exe
      @dnetinstaller_output_exe || File.join(@wix_project_directory,
                                             'bin',
                                             configuration.to_s,
                                             "#{@wix_project_directory} #{@product_version} Installer.exe")
    end

    def dnetinstaller_xml_config
      @dnetinstaller_xml_config || File.join(@wix_project_directory,
                                             'dnetinstaller.xml')
    end

    def properties
      if @properties && @properties.include?(:Configuration) then
        raise "You cannot supply #{@properties[:Configuration]} for a :Configuration property.  Use the :release_mode property on the WixCoordinator task"
      end
      standard_props = {:ProductVersion => @product_version,
                        :UpgradeCode => @upgrade_code}
      @properties ? standard_props.merge(@properties) : standard_props
    end

    def paraffin_update_fragment
      @paraffin_update_fragment || File.join(@wix_project_directory, 'paraffin', 'binaries.wxs')
    end

    def validate
      raise ':product_version, :upgrade_code, :wix_project_directory are all required' unless @product_version && @upgrade_code && @wix_project_directory
    end
  end
end