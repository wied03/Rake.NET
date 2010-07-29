require "base"
require "basetask"
require "basetaskmocking"

describe BW::BaseTask do
  before(:each) do
    Rake::Task.clear
  end

  it "Task with no dependencies/default name" do
    task = BW::BaseTask.new
    task.name.should == :task
    task.dependencies.should == nil
    task.unless.should == nil
    task.should_receive(:exectask)
    Rake::Task[:task].invoke
    task.testoutput.should == "Running task: task"
  end

  it "Task with no dependencies/custom name" do
    task = BW::BaseTask.new "mytask"
    task.name.should == "mytask"
    task.dependencies.should == nil
    task.unless.should == nil
    task.should_receive(:exectask)
    Rake::Task[:mytask].invoke
    task.testoutput.should == "Running task: mytask"
  end

  it "Task with dependencies/custom name" do
    task = BW::BaseTask.new "mytask" => :dependenttask
    task.name.should == "mytask"
    task.dependencies.should == :dependenttask
    task.unless.should == nil

    dtask = BW::BaseTask.new "dependenttask"
    task.should_receive(:exectask)
    dtask.should_receive(:exectask)
    Rake::Task[:mytask].invoke

    dtask.testoutput.should == "Running task: dependenttask"
    task.testoutput.should == "Running task: mytask"
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
    Rake::Task[:mytask].invoke

    task.testoutput.should == "Skipping task: mytask due to unless condition specified in rakefile"
  end
end