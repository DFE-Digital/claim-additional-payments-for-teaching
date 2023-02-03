module Hmrc
  class BankAccountVerificationResponse
    attr_reader :payload

    delegate :code, to: :payload

    def initialize(payload)
      @payload = payload
    end

    def body
      @body ||= JSON.parse(payload.body)
    end

    def name_match?
      ["yes", "partial"].include? body["nameMatches"]
    end

    def sort_code_correct?
      body["sortCodeIsPresentOnEISCD"] == "yes"
    end

    def account_exists?
      body["accountExists"] == "yes"
    end
  end
end
