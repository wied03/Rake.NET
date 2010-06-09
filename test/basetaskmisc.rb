require 'base'
require 'rake'
require 'rake/tasklib'

module BW
	class BaseTask < Rake::TaskLib
		attr_accessor :dependencies, :testdiditrun, :testoutput

        def exectaskpublic
          exectask
        end

        def log text
          @testoutput = text
          puts text
        end

        def BaseTask.sh2command cmd
          @@sh2 = cmd
        end

        def sh
          @@sh2
        end
    end
end

def sh2 cmd
  puts cmd
  # We aren't testing concurrent tasks here, so no thread safety worries
  BW::BaseTask.sh2command cmd
end