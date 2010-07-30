require "base"
require "basetask"
require "basetaskmocking"

module BW
  class BaseTask < Rake::TaskLib
    attr_accessor :dependencies
  end
end

describe BW::BaseTask do
  before(:each) do
    Rake::Task.clear
  end

  it "Task with no dependencies/default name" do
    task = BW::BaseTask.new
    task.should_receive(:log).with("Running task: task")
    task.name.should == :task
    task.dependencies.should == nil
    task.unless.should == nil
    task.should_receive(:exectask)
    Rake::Task[:task].invoke
  end

  it "Task with no dependencies/custom name" do
    task = BW::BaseTask.new "mytask"
    task.should_receive(:log).with("Running task: mytask")
    task.name.should == "mytask"
    task.dependencies.should == nil
    task.unless.should == nil
    task.should_receive(:exectask)
    Rake::Task[:mytask].invoke
  end

  it "Task with dependencies/custom name" do
    task = BW::BaseTask.new "mytask" => :dependenttask
    task.name.should == "mytask"
    task.dependencies.should == :dependenttask
    task.unless.should == nil

    dtask = BW::BaseTask.new "dependenttask"
    task.should_receive(:exectask)
    dtask.should_receive(:exectask)

    task.should_receive(:log).with("Running task: mytask")
    dtask.should_receive(:log).with("Running task: dependenttask")
    Rake::Task[:mytask].invoke
  end

  it "Task with dependencies/custom name + block" do
    task = BW::BaseTask.new "mytask" => [:dependenttask, :test] do |t|
      t.unless = "yes"
    end
    task.name.should == "mytask"
    task.dependencies.should == [:dependenttask, :test]
    task.unless.should == "yes"

    dtask = BW::BaseTask.new "dependenttask"
    task.should_not_receive(:exectask)
    dtask.should_not_receive(:exectask)

    task.should_receive(:log).with("Skipping task: mytask due to unless condition specified in rakefile")
    Rake::Task[:mytask].invoke
  end
end