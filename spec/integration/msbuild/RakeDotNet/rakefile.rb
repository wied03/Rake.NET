require 'rakedotnet'

solution = 'RakeDotNet.sln'
BradyW::MSBuild.new :clean do |clean|
  clean.targets = 'clean'
  clean.solution = solution
end

BradyW::MSBuild.new :build do |build|
  build.solution = solution
end
