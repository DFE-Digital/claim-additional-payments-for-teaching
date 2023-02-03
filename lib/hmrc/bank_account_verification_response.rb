module Hmrc
  class BankAccountVerificationResponse
    delegate :code, :body, to: :payload

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

    attr_reader :payload
  end
end
