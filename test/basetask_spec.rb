require "base"
require "basetask"
require "basetaskmisc"

# Need to get access to our private dependencies property
module BW
	class BaseTask < Rake::TaskLib
		attr_accessor :testdiditrun
        
        def exectask
          @testdiditrun = true
        end        
    end
end

describe "Base Task" do
  before(:each) do
    Rake::Task.clear
  end

  it "Task with no dependencies/default name" do
    task = BW::BaseTask.new
    task.name.should == :task
    task.dependencies.should == nil
    task.unless.should == nil
    Rake::Task[:task].invoke
    task.testdiditrun.should == true
    task.testoutput.should == "Running task: task"
  end

  it "Task with no dependencies/custom name" do
    task = BW::BaseTask.new "mytask"
    task.name.should == "mytask"
    task.dependencies.should == nil
    task.unless.should == nil
    Rake::Task[:mytask].invoke
    task.testdiditrun.should == true
    task.testoutput.should == "Running task: mytask"
  end

  it "Task with dependencies/custom name" do
    task = BW::BaseTask.new "mytask" => :dependenttask
    task.name.should == "mytask"
    task.dependencies.should == :dependenttask
    task.unless.should == nil
    
    dtask = BW::BaseTask.new "dependenttask"
    Rake::Task[:mytask].invoke
    
    task.testdiditrun.should == true
    dtask.testdiditrun.should == true
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
    Rake::Task[:mytask].invoke

    task.testdiditrun.should == nil
    dtask.testdiditrun.should == nil    
    task.testoutput.should == "Skipping task: mytask due to unless condition specified in rakefile"
  end
end