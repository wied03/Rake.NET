require 'basetask'

module BradyW

  # Minifies Javascript files using the Yahoo YUI tool
  class MinifyJs < BaseTask

    # *Required* Which files do you want to minify (in place)?
    attr_accessor :files

    # *Optional* Version of YUI tool to use (defaults to 2.4.2)
    attr_accessor :version

    # *Optional* Charset to use (defaults to "utf-8")
    attr_accessor :charset

    # *Optional* Where is the YUI compressor JAR? (defaults to "lib/")
    attr_accessor :path
    
    private
    
    def exectask		
	  puts "YUI Javscript Minify:  Minifying these files: #{files}"
	  files.each do |j|
        shell "java -jar #{path}yuicompressor-#{version}.jar --charset #{charset} #{j} -o #{j}"
	  end
    end	
	
	def charset
      @charset || "utf-8"
	end
	
	def version
      @version || "2.4.2"
	end
	
	def path
      @path || "lib/"
	end
  end
end