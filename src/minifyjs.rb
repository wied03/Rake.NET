require 'bwbuild/basetask'

module BW
  class MinifyJs < BaseTask   
    attr_accessor :files, :version, :charset, :path  
    
    # Create the tasks defined by this task lib.
    def exectask		
		puts "YUI Javscript Minify:  Minifying these files: #{files}"
		files.each do |j|
			sh2 "java -jar #{path}yuicompressor-#{version}.jar #{charset} #{j} -o #{j}"
		end
    end	
	
	def charset
		if @charset
			@charset
		else
			"--charset utf-8"
		end
	end
	
	def version
		if @version
			@version
		else
			"2.4.2"
		end
	end
	
	def path
		if @path
			@path
		else
			"bwbuild/lib/"
		end
	end
  end
end