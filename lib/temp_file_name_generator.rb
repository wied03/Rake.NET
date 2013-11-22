module BradyW
  class TempFileNameGenerator
    def self.filename(originalFileName)
      dir = File.dirname originalFileName
      filename = File.basename originalFileName
      ext = File.extname filename
      withoutExt = filename.sub "#{ext}", ''
      tempFileName = "#{withoutExt}_#{DateTime.now.strftime('%s')}#{ext}"
      File.join dir, tempFileName
    end
  end
end