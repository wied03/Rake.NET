require 'spec_helper'

module BradyW
  class BaseTask < Rake::TaskLib
    attr_accessor :dependencies
  end
end

describe BradyW::BaseTask do
  before(:each) do
    Rake::Task.clear
  end

  it "Task with no dependencies/default name" do
    task = BradyW::BaseTask.new
    expect(task).to receive(:log).with("Running task: task")
    expect(task).to receive(:exectask)
    expect(task.name).to eq :task
    task.dependencies.should == nil
    task.unless.should == nil
    Rake::Task[:task].invoke
  end

  it "Task with no dependencies/custom name" do
    task = BradyW::BaseTask.new "mytask"
    expect(task).to receive(:log).with("Running task: mytask")
    expect(task).to receive(:exectask)
    task.name.should == "mytask"
    task.dependencies.should == nil
    task.unless.should == nil
    Rake::Task[:mytask].invoke
  end

  it "Task with dependencies/custom name" do
    task = BradyW::BaseTask.new "mytask" => :dependenttask
    task.name.should == "mytask"
    task.dependencies.should == :dependenttask
    task.unless.should == nil

    dtask = BradyW::BaseTask.new "dependenttask"
    expect(task).to receive(:exectask)
    expect(dtask).to receive(:exectask)

    expect(task).to receive(:log).with("Running task: mytask")
    expect(dtask).to receive(:log).with("Running task: dependenttask")
    Rake::Task[:mytask].invoke
  end

  it "Task with dependencies/custom name + block" do
    task = BradyW::BaseTask.new "mytask" => [:dependenttask, :test] do |t|
      t.unless = "yes"
    end
    task.name.should == "mytask"
    task.dependencies.should == [:dependenttask, :test]
    task.unless.should == "yes"

    dtask = BradyW::BaseTask.new "dependenttask"
    expect(task).to_not receive(:exectask)
    expect(dtask).to_not receive(:exectask)

    expect(task).to receive(:log).with("Skipping task: mytask due to unless condition specified in rakefile")
    Rake::Task[:mytask].invoke
  end
end
