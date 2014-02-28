%w[
  util/config
  util/tools

  build/msbuild

  db/database
  db/bcp
  db/sqlcmd

  security/sign_tool
  security/subinacl

  install/paraffin/fragment_generator
  install/paraffin/fragment_updater
  install/dot_net_installer
  install/dot_net_installer_execute
  install/wix_coordinator

  test/jstest
  test/mstest
  test/nunit

  web/iis
  web/minifyjs

].each {|name| require_relative name}
