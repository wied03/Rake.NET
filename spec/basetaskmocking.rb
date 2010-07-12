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

        def shell(*cmd, &block)
          command = cmd.first
          puts command
          # We aren't testing concurrent tasks here, so no thread safety worries
          if !@sh
            @sh = []
          end

          @sh << command
          
          # Make it look like it went OK
          yield true, nil if block_given?
        end

        def excecutedPop
          return nil unless @sh
          @sh.pop()
        end
    end
end

class SimulateProcessFailure
  def exitstatus
    return "BW Rake Task Problem"
  end
end

def rm_rf directory
  # Before we delete the files, copy them to a place where we can verify their correctness
  if File.exist? directory
    FileUtils::cp_r directory, "data/output"
  end
  FileUtils::rm_rf directory
end