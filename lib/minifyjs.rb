require 'basetask'

module BW
  class MinifyJs < BaseTask   
    attr_accessor :files, :version, :charset, :path  
    
    private
    
    def exectask		
	  puts "YUI Javscript Minify:  Minifying these files: #{files}"
	  files.each do |j|
        sh "java -jar #{path}yuicompressor-#{version}.jar --charset #{charset} #{j} -o #{j}"
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