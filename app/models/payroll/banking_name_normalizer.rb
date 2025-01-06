module Payroll
  class BankingNameNormalizer
    def self.normalize(name)
      new(name).normalize
    end

    def initialize(name)
      @name = name
    end

    def normalize
      return nil if @name.nil?

      @name
        .then { |n| strip(n) }
        .then { |n| final_cleanup(n) }
    end

    private

    # CAPT-2088 - if we strip spaces in form objects this would't be needed
    # Payroll requires this can't have leading spaces
    def strip(name)
      name.strip
    end

    # Just remove anything that isn't allowed by Payroll
    # BankDetailsForm::BANKING_NAME_REGEX_FILTER is actually stricter than what is allowed here
    # So there is no need to worry about UTF-8 issues
    def final_cleanup(name)
      name.gsub(/[^A-Za-z0-9 &'()*,-.\/]/, "")
    end
  end
end
