module Hmrc
  class BankAccountVerificationResponse
    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end

    def body
      @body ||= JSON.parse(payload.body)
    end

    def code
      if payload.respond_to?(:status)
        payload.status
      else
        payload.code
      end
    end

    def success?
      name_match? && sort_code_correct? && account_exists?
    end

    def name_match?
      ["yes", "partial"].include? name_matches
    end

    def sort_code_correct?
      sort_code_present_on_eiscd == "yes"
    end

    def account_exists?
      account_exists == "yes"
    end

    def sort_code_present_on_eiscd
      body["sortCodeIsPresentOnEISCD"]
    end

    def account_exists
      body["accountExists"]
    end

    def name_matches
      body["nameMatches"]
    end
  end
end
