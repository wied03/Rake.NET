module BradyW
  class TempFileNameGenerator
    def self.random_filename(base,ext)
      "#{base}_#{DateTime.now.strftime('%s')}#{ext}"
    end

    def self.from_existing_file(originalFileName)
      dir = File.dirname originalFileName
      filename = File.basename originalFileName
      ext = File.extname filename
      withoutExt = filename.sub "#{ext}", ''
      tempFileName = random_filename withoutExt, ext
      File.join dir, tempFileName
    end
  end
end