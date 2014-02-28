module BradyW
  module DotNetVersionSymbolToNumberConverter
    def convertToNumber symbol
      trimmedV = symbol.to_s()[1..-1]
      trimmedV.gsub(/_/, '.')
    end
  end
end