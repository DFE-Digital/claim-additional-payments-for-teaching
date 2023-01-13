module Hmrc
  class BankAccountVerificationResponse
    def initialize(payload)
      self.payload = payload
    end

    def name_match?
      ["yes", "partial"].include? payload["nameMatches"]
    end

    def sort_code_correct?
      payload["sortCodeIsPresentOnEISCD"] == "yes"
    end

    def account_exists?
      payload["accountExists"] == "yes"
    end

    private

    attr_accessor :payload
  end
end
