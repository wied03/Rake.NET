require 'spec_helper'
require 'rake'
require 'rake/tasklib'

module BradyW
  class BaseTask < Rake::TaskLib
    def self.clear_shell_stack
      @@sh = []
    end

    def exectaskpublic
      exectask
    end

    def shell(*cmd, &block)
      command = cmd.first
      puts command
      # We aren't testing concurrent tasks here, so no thread safety worries
      @@sh << command

      # Make it look like it went OK
      yield true, nil if block_given?
    end

    def executedPop
      BaseTask.pop_executed_command
    end

    def self.pop_executed_command
      return nil unless @@sh
      @@sh.pop
    end
  end
end

class SimulateProcessFailure
  def exitstatus
    'BW Rake Task Problem'
  end
end

def rm_safe directory
  # Before we delete the files, copy them to a place where we can verify their correctness
  if File.exist? directory
    FileUtils::cp_r directory, 'data/output'
  end
  FileUtils::rm_rf directory
end