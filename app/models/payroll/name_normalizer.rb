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
        .then { |n| remove_typical_disallowed_chars(n) }
        .then { |n| transliterate(n) }
        .then { |n| final_cleanup(n) }
    end

    private

    # Things we allow from `NameFormatValidator` and typically found in names
    # but Payroll provider doesn't accept
    # Also handles curly apostrophe commonly found
    def remove_typical_disallowed_chars(name)
      name.gsub(/[,.;\-'‘’\s]/, "")
    end

    # Attempt to replace things like `è` with `e`
    def transliterate(name)
      I18n.transliterate(name)
    end

    # Just remove anything missed that aren't allowed by Payroll
    def final_cleanup(name)
      name.gsub(/[^A-Za-z]/, "")
    end
  end
end
