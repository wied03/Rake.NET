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

        @@sh2 = []
        
        def BaseTask.sh2command cmd
          @@sh2 << cmd
        end

        def sh
          @@sh2.pop()
        end
    end
end

def sh2 cmd
  puts cmd
  # We aren't testing concurrent tasks here, so no thread safety worries
  BW::BaseTask.sh2command cmd
end

def rm_rf directory
  # Before we delete the files, copy them to a place where we can verify their correctness
  if File.exist? directory
    FileUtils::cp_r directory, File.expand_path(File.dirname(__FILE__))+"/data/output"
  end
  FileUtils::rm_rf directory
end