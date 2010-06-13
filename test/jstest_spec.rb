require "base"
require "jstest"
require "basetaskmocking"

def jspath
  FileList["data/jstest/path/**/*.js"]
end

describe "Task: JSTest" do
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

    expected = IO.readlines("data/jstest/jsTestDriver_expected.conf")
    actual = IO.readlines("data/output/jsTestDriver.conf")

    actual.should == expected
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

    expected = IO.readlines("data/jstest/jsTestDriver_expected.conf")
    actual = IO.readlines("data/output/jsTestDriver.conf")

    actual.should == expected
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

    expected = IO.readlines("data/jstest/jsTestDriver_expected.conf")
    actual = IO.readlines("data/output/jsTestDriver.conf")

    actual.should == expected
  end

  it "Custom version, Test Output, JAR path, port, and server" do
    ENV["CCNetProject"] = "yes"
    task = BW::JsTest.new do |js|
      js.files = jspath
      js.jarpath = "newpath/"
      js.port = "1234"
      js.server = "anotherbox"
      js.outpath = "testdir"
    end

    task.exectaskpublic
    task.excecutedPop.should == "java -jar newpath/jsTestDriver-1.2.1.jar "+
            "--tests all --testOutput testdir"

    expected = IO.readlines("data/jstest/jsTestDriver_expected_custom.conf")
    actual = IO.readlines("data/output/jsTestDriver.conf")

    actual.should == expected
  end

end