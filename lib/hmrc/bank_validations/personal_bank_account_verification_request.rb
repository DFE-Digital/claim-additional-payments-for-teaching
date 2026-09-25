module Hmrc
  module BankValidations
    class PersonalBankAccountVerificationRequest
      def initialize(sort_code:, account_number:, name:)
        @sort_code = sort_code
        @account_number = account_number
        @name = name
      end

      def path
        "/misc/bank-account/verify/personal"
      end

      def payload
        {
          account: {
            sortCode: @sort_code,
            accountNumber: @account_number
          },
          subject: {
            name: @name
          }
        }.to_json
      end

      def headers(token:)
        {
          "Content-Type" => "application/json",
          "Accept" => "application/vnd.hmrc.1.0+json",
          "User-Agent" => "dfe-claim-additional-payments",
          "Authorization" => "Bearer #{token}"
        }
      end
    end
  end
end
