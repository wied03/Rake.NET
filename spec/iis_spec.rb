require "base"
require "iis"
require "basetaskmocking"

describe "Task: IIS Start/Stop" do

  it "Standard Command" do
    task = BW::IIS.new do |task|
      task.command = :start
    end

    task.exectaskpublic
    task.excecutedPop.should == "net.exe start W3SVC"
  end

  it "Forgot Command" do
    task = BW::IIS.new
    lambda {task.exectaskpublic}.should raise_exception("You forgot to supply a service command (:start, :stop)")
  end

  it "Custom Service With Failure on STOP" do
    task = BW::IIS.new do |task|
      task.command = :stop
      task.service = "SVC"
    end

    task.stub!(:shell).and_yield(nil, SimulateProcessFailure.new)
    task.exectaskpublic
  end

  it "Standard Service With Failure on some other command" do
    task = BW::IIS.new do |task|
      task.command = :start
    end

    task.stub!(:shell).and_yield(nil, SimulateProcessFailure.new)
    lambda {task.exectaskpublic}.should raise_exception(RuntimeError,
                                                         "Command failed with status (BW Rake Task Problem):")
  end

  it "Standard Service With Success on STOP" do
    task = BW::IIS.new do |task|
      task.command = :stop
    end

    task.exectaskpublic
    task.excecutedPop.should == "net.exe stop W3SVC"
  end
end