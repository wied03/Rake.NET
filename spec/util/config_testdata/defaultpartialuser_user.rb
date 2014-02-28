require_relative 'defaultpartialuser_default'

module TestCase_2
  class UserConfig < TestCase_2::ADefaultConfig
    def setting
      "overrodethis"
    end
  end
end
