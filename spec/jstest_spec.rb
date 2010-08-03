require "base"
require "jstest"
require "basetaskmocking"

def jspath
  FileList["data/jstest/path/**/*.js"]
end

Spec::Matchers.define :have_same_config_as do |e|
    expected = YAML::load(File.read(e))
    match do |a|
      actual = YAML::load(File.read(a))
      actual['server'].should == expected['server']
      expLoad = expected['load']
      actLoad = actual['load']
      expLoad.each { |file| actLoad.should include file }
      actLoad.each { |file| expLoad.should include file }
    end

    failure_message_for_should do |a|
      actual = YAML::load(File.read(a))
      expSvr = expected['server']
      actSvr = actual['server']
      expLoad = expected['load'].join("\n")
      actLoad = actual['load'].join("\n")
      "Expected server #{expSvr} but got #{actSvr}.\n\nExpected Files:\n#{expLoad}\n\nActual Files:\n#{actLoad}"
    end
end

describe BW::JsTest do
  before(:each) do
    ENV["CCNetProject"] = nil
  end

  after(:each) do
    # Remove our generated test data
    FileUtils::rm_rf "data/output/jsTestDriver.conf"
  end

  it "Standard Test With Browsers and Files" do
    task = BW::JsTest.new do |js|
      js.browsers = ["iexplore.exe", "firefox.exe"]
      js.files = jspath
    end

    task.exectaskpublic
    task.excecutedPop.should == "java -jar lib/jsTestDriver-1.2.1.jar --port 9876 "+
            "--browser iexplore.exe,firefox.exe --tests all"

    "data/output/jsTestDriver.conf".should have_same_config_as "data/jstest/jsTestDriver_expected.conf"
  end

  it "Standard Test With Browsers and Files In CI tool" do
    ENV["CCNetProject"] = "yes"
    task = BW::JsTest.new do |js|
      js.browsers = ["iexplore.exe", "firefox.exe"]
      js.files = jspath
    end

    task.exectaskpublic
    task.excecutedPop.should == "java -jar lib/jsTestDriver-1.2.1.jar --port 9876 "+
            "--browser iexplore.exe,firefox.exe --tests all --testOutput ."

    "data/output/jsTestDriver.conf".should have_same_config_as "data/jstest/jsTestDriver_expected.conf"
  end

  it "Standard Test With Browsers and Files with manual XML config" do
    task = BW::JsTest.new do |js|
      js.browsers = ["iexplore.exe", "firefox.exe"]
      js.files = jspath
      js.xmloutput = true
    end

    task.exectaskpublic
    task.excecutedPop.should == "java -jar lib/jsTestDriver-1.2.1.jar --port 9876 "+
            "--browser iexplore.exe,firefox.exe --tests all --testOutput ."

    "data/output/jsTestDriver.conf".should have_same_config_as "data/jstest/jsTestDriver_expected.conf"
  end

  it "Custom version, Test Output, JAR path, port, and server" do
    ENV["CCNetProject"] = "yes"
    task = BW::JsTest.new do |js|
      js.files = jspath
      js.jarpath = "newpath/"
      js.port = 1234
      js.server = "anotherbox"
      js.outpath = "testdir"
    end

    task.exectaskpublic
    task.excecutedPop.should == "java -jar newpath/jsTestDriver-1.2.1.jar "+
            "--tests all --testOutput testdir"

    "data/output/jsTestDriver.conf".should have_same_config_as "data/jstest/jsTestDriver_expected_custom.conf"
  end

  it "Should clean up generated file if JS-Test-Driver fails" do
    task = BW::JsTest.new do |js|
      js.browsers = ["iexplore.exe", "firefox.exe"]
      js.files = jspath
    end

    task.stub!(:shell).and_yield(nil, SimulateProcessFailure.new)

    lambda {task.exectaskpublic}.should raise_exception("Command failed with status (BW Rake Task Problem):")

    # This means our temporary file was correctly cleaned up
    File.exist?("jsTestDriver.conf").should_not == true
    # Our test code should have done this
    File.exist?("data/output/jsTestDriver.conf").should == true    
  end

end