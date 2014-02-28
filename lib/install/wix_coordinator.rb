module BradyW
  class WixCoordinator < BaseTask
    # *Required* Product version to configure in the WIX/MSBUild + DotNetInstaller
    attr_accessor :product_version

    # *Required* The directory containing your .wixproj file
    attr_accessor :wix_project_directory

    # *Required* Upgrade code that is passed on to WIX and dotnetinstaller
    attr_accessor :upgrade_code

    # *Required* The installer referencer directory that Paraffin will scan for files
    attr_accessor :installer_referencer_bin

    # *Optional* Fragment file that will be updated with Paraffin before calling MSBuild.  By default it's @wix_project_directory/paraffin/binaries.wxs
    attr_accessor :paraffin_update_fragment

    # *Optional* Location of the DotNetInstaller XML config file.  By default it's @wix_project_directory/dnetinstaller.xml
    attr_accessor :dnetinstaller_xml_config

    # *Optional* The name of the output file you want.  By default it's @wix_project_directory/bin/[Debug|Release]/Project Name v[version] Installer.exe
    attr_accessor :dnetinstaller_output_exe

    # *Optional* Properties to be used with MSBuild and DotNetInstaller
    attr_accessor :properties

    # *Optional* :Debug or :Release.  By default :Release is used
    attr_accessor :build_config

    # *Optional* A lambda to do additional configuration on the MSBuild task (e.g. dotnet_bin_version)
    attr_accessor :msbuild_configure

    # *Optional* Path to the MSI generated by the WIX msbuild project. By default it's @wix_project_directory/bin/Debug|Release/project name.msi
    attr_accessor :msi_path

    # *Optional* The manifest file that should be used with the bootstrapper
    attr_accessor :bootstrapper_manifest

    # *Optional* Certificate subject to use with the signtool task when signing the MSI + exe
    attr_accessor :certificate_subject

    # *Optional* Description to use with the signtool task when signing the MSI + exe
    attr_accessor :description

    # *Optional* Timestamp URL for code signing, if not specified, will use default of code sign task
    attr_accessor :code_sign_timestamp_server

    def initialize(parameters = :task)
      @release_mode ||= true

      yield self if block_given?
      # Need our parameters to instantiate the dependent tasks
      parseParams parameters

      # Allow Paraffin to run separately
      if @wix_project_directory || @paraffin_update_fragment then
        desc 'Updates Paraffin fragment on its own (without doing a build first)'
        paraffin = Paraffin::FragmentUpdater.new "paraffin_#{@name}" => [*@dependencies] do |pf|
          pf.fragment_file = paraffin_update_fragment
          pf.output_directory = @installer_referencer_bin
        end
      end

      if not is_valid then
        log "WixCoordinator task is missing required parameters, will raise exception if executed"
        # This task specifies its own dependencies and in this case, won't specify any since we want an error to be thrown upon execution
        @dependencies = nil
        super(@name)
        return
      end

      desc 'Run MSBuild and produce an MSI for the WIX project'
      msb = BradyW::MSBuild.new "wixmsbld_#{@name}" do |m|
        m.build_config = configuration
        m.solution = wix_project_file
        m.properties = properties.merge(wix_constants)
        @msbuild_configure.call(m) if @msbuild_configure
      end

      sign_code_task = lambda do |task_name_dependencies, sign_this|
        desc "Signs the #{sign_this} as part of the build process"
        BradyW::SignTool.new task_name_dependencies do |s|
          s.subject = @certificate_subject
          s.description = @description
          s.sign_this = sign_this
          s.timestamp_url = @code_sign_timestamp_server
        end
      end

      if signing_code? then
        sign_msi_task_name = "signmsi_#{@name}"
        sign_code_task[{sign_msi_task_name => msb.name}, msi_path]
      end

      dnet_inst_task_name = "dnetinst_#{@name}"
      dnet_name_deps = signing_code? ? {dnet_inst_task_name => sign_msi_task_name} : dnet_inst_task_name
      desc 'Produces a complete .NET installer build using dotNetInstaller as bootstrapper'
      BradyW::DotNetInstaller.new dnet_name_deps do |inst|
        inst.xml_config = dnetinstaller_xml_config
        tokens = {:Configuration => configuration,
                  :MsiPath => msi_path,
                  :MsiFileName => File.basename(msi_path)}
        tokens = properties.merge tokens
        inst.tokens = tokens
        inst.output = dnetinstaller_output_exe
        inst.manifest = @bootstrapper_manifest if @bootstrapper_manifest
      end

      @dependencies = [*@dependencies] + [paraffin.name,
                                          msb.name,
                                          dnet_inst_task_name]

      if signing_code? then
        sign_exe_task_name = "signexe_#{@name}"
        sign_code_task[{sign_exe_task_name => dnet_inst_task_name}, dnetinstaller_output_exe]
        @dependencies << sign_exe_task_name
      end

      # Specifying our own dependencies
      super(@name)
    end

    def exectask
      # We're just a task of dependencies
      validate
    end

    private

    def signing_code?
      @certificate_subject && @description
    end

    def wix_project_dir_name_only
      File.basename @wix_project_directory
    end

    def wix_project_file
      File.join @wix_project_directory, "#{wix_project_dir_name_only}.wixproj"
    end

    def configuration
      @build_config ? @build_config.to_sym : :Release
    end

    def bin_dir
      File.join(@wix_project_directory,
                'bin',
                configuration.to_s)
    end

    def msi_path
      @msi_path || File.join(bin_dir,
                             "#{wix_project_dir_name_only}.msi")
    end

    def dnetinstaller_output_exe
      @dnetinstaller_output_exe || File.join(bin_dir,
                                             "#{wix_project_dir_name_only} #{@product_version}.exe")
    end

    def dnetinstaller_xml_config
      @dnetinstaller_xml_config || File.join(@wix_project_directory,
                                             'dnetinstaller.xml')
    end

    def handle_property_semicolon(val)
      val_str = val.to_s
      val_str.gsub(/;/, '%3B')
    end

    def property_kv(key, value)
      "#{key}=#{handle_property_semicolon(value)}"
    end

    def wix_constants
      props_array = []
      # This is a default in .wixproj files
      props_array << 'Debug' if configuration == :Debug
      props_array << properties.map { |k, v| property_kv(k, v) }
      # Preprocessor variables in projects built using traditional .csproj files need these next 2 and .csproj builds may be triggered by the WIX build
      props_array << 'DEBUG' if configuration == :Debug
      props_array << 'TRACE'
      props_flat = props_array.join ';'
      {
          :DefineConstants => props_flat
      }
    end

    def properties
      if @properties && @properties.include?(:Configuration) then
        raise "You cannot supply #{@properties[:Configuration]} for a :Configuration property.  Use the :build_config property on the WixCoordinator task"
      end
      standard_props = {:ProductVersion => @product_version,
                        :UpgradeCode => @upgrade_code}
      @properties ? standard_props.merge(@properties) : standard_props
    end

    def paraffin_update_fragment
      @paraffin_update_fragment || File.join(@wix_project_directory, 'paraffin', 'binaries.wxs')
    end

    def validate
      raise ':product_version, :upgrade_code, :wix_project_directory, and :installer_referencer_bin are all required' unless is_valid
    end

    def is_valid
      @product_version && @upgrade_code && @wix_project_directory  && @installer_referencer_bin
    end
  end
end