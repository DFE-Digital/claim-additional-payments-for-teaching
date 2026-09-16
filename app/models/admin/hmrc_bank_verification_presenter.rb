module Admin
  class HmrcBankVerificationPresenter
    SORT_CODE_MESSAGES = {
      "yes" => "Yes - sort code found",
      "no" => "No - sort code not found"
    }.freeze

    ACCOUNT_NUMBER_MESSAGES = {
      "yes" => "Yes - sort code and account number match",
      "no" => "No - sort code and account number do not match"
    }.freeze

    NAME_MESSAGES = {
      "yes" => "Yes - name matches the account holder name",
      "partial" => "Partial - name partially matches the account holder name",
      "no" => "No - name does not match the account holder name"
    }.freeze

    UNKNOWN_MESSAGE = "Unknown - HMRC did not return an answer"

    def initialize(hmrc_bank_validation_response)
      @body = hmrc_bank_validation_response.fetch("body")
      @code = hmrc_bank_validation_response.fetch("code")
    end

    def success?
      !errored? && sort_code_found? && account_number_matches? && name_matches?
    end

    def title
      if success?
        "Bank details verified with HMRC"
      else
        "Bank details could not be verified with HMRC"
      end
    end

    def rows
      [
        "Sort code: #{SORT_CODE_MESSAGES.fetch(sort_code_present_on_eiscd, UNKNOWN_MESSAGE)}",
        "Account number: #{ACCOUNT_NUMBER_MESSAGES.fetch(account_exists, UNKNOWN_MESSAGE)}",
        "Name on the account: #{NAME_MESSAGES.fetch(name_matches, UNKNOWN_MESSAGE)}"
      ]
    end

    def errored?
      @code.to_i > 300
    end

    private

    attr_reader :body

    def sort_code_found?
      sort_code_present_on_eiscd == "yes"
    end

    def account_number_matches?
      account_exists == "yes"
    end

    def name_matches?
      name_matches == "yes"
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
