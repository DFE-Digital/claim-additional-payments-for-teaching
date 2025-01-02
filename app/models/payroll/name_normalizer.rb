module Payroll
  class NameNormalizer
    def self.normalize(name)
      new(name).normalize
    end

    def initialize(name)
      @name = name
    end

    def normalize
      return nil if @name.nil?

      @name
        .then { |n| transliterate(n) }
        .then { |n| final_cleanup(n) }
    end

    private

    # Transliterates UTF-8 characters to ASCII
    # Attempt to replace things like `è` with `e`
    def transliterate(name)
      I18n.transliterate(name)
    end

    # Just remove anything that isn't allowed by Payroll
    def final_cleanup(name)
      name.gsub(/[^A-Za-z]/, "")
    end
  end
end
