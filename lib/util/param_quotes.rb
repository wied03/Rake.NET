module BradyW
  module ParamQuotes
    def switch_and_param(switch, setting, options={})
      return String.new unless setting
      specifier = options[:specifier] || '-'
      quoted = options[:quote] ? quoted(setting) : setting
      "#{specifier}#{switch} #{quoted}"
    end

    def param_fslash(switch, setting, options={})
      switch_and_param(switch, setting, options.merge({:specifier => '/'}))
    end

    def param_fslash_eq(switch, setting, options={})
      return String.new unless setting
      quoted = options[:quote] ? quoted(setting) : setting
      "/#{switch}=#{quoted}"
    end

    def param_fslash_colon(switch, setting, options={})
      return String.new unless setting
      quoted = options[:quote] ? quoted(setting) : setting
      "/#{switch}:#{quoted}"
    end

    def quoted(setting)
      "\"#{setting}\""
    end

    def quoted_for_spaces(value)
      value.include?(' ') ? quoted(value) : value
    end
  end
end
