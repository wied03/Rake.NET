module BradyW
  module ParamQuotes
    def switch_and_param(switch, setting, options={})
      return String.new if !setting
      specifier = options[:specifier] || '-'
      quoted = options[:quote] ? quoted(setting) : setting
      "#{specifier}#{switch} #{quoted}"
    end

    def param_fslash_colon(switch, setting, options={})
      return String.new if !setting
      quoted = options[:quote] ? quoted(setting) : setting
      "/#{switch}:#{quoted}"
    end

    def quoted(setting)
      "\"#{setting}\""
    end
  end
end