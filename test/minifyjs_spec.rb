require "base"
require "minifyjs"
require "basetaskmisc"

describe "Task: Minify JS" do

  it "Should work with default settings" do
    task = BW::MinifyJs.new do |task|
      task.files = ["file1.js", "file2.js"]
    end
    task.exectaskpublic
    task.excecutedPop.should == "java -jar lib/yuicompressor-2.4.2.jar --charset utf-8 file2.js -o file2.js"
    task.excecutedPop.should == "java -jar lib/yuicompressor-2.4.2.jar --charset utf-8 file1.js -o file1.js"
  end

  it "Should work with custom settings" do
    task = BW::MinifyJs.new do |task|
      task.files = ["file1.js", "file2.js"]
      task.version = "3.0"
      task.charset = "ascii"
      task.path = "newpath/"
    end
    task.exectaskpublic
    task.excecutedPop.should == "java -jar newpath/yuicompressor-3.0.jar --charset ascii file2.js -o file2.js"
    task.excecutedPop.should == "java -jar newpath/yuicompressor-3.0.jar --charset ascii file1.js -o file1.js"
  end
end