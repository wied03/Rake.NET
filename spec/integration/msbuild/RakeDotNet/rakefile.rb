require 'rakedotnet'

BradyW::MSBuild.new :clean do |clean|
  clean.targets = 'clean'
end

BradyW::MSBuild.new :build
