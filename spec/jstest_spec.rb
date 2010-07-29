require "base"
require "jstest"
require "basetaskmocking"

def jspath
  FileList["data/jstest/path/**/*.js"]
end

Spec::Matchers.define :same_js_config do |expected|
    match do |actual|
      expected['server'] == actual['server']
      expLoad = expected['load']
      actLoad = actual['load']
      expLoad.each { |file| actLoad.should include file }
      actLoad.each { |file| expLoad.should include file }
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

    expected = YAML::load(File.read("data/jstest/jsTestDriver_expected.conf"))
    actual = YAML::load(File.read("data/output/jsTestDriver.conf"))

    actual.should same_js_config(expected)    
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

    expected = YAML::load(File.read("data/jstest/jsTestDriver_expected.conf"))
    actual = YAML::load(File.read("data/output/jsTestDriver.conf"))    

    actual.should same_js_config(expected)
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

    expected = YAML::load(File.read("data/jstest/jsTestDriver_expected.conf"))
    actual = YAML::load(File.read("data/output/jsTestDriver.conf"))

    actual.should same_js_config(expected)
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

    expected = YAML::load(File.read("data/jstest/jsTestDriver_expected_custom.conf"))
    actual = YAML::load(File.read("data/output/jsTestDriver.conf"))

    actual.should same_js_config(expected)
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