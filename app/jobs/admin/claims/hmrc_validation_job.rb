module Admin
  module Claims
    class HmrcValidationJob < ApplicationJob
      def perform(claim)
        response = Hmrc.client.verify_personal_bank_account(
          claim.bank_sort_code,
          claim.bank_account_number,
          claim.banking_name
        )

        hmrc_bank_validation_responses = claim.hmrc_bank_validation_responses

        hmrc_bank_validation_responses << {
          code: response.status,
          body: response.safe_body
        }

        claim.update!(
          hmrc_bank_validation_responses: hmrc_bank_validation_responses
        )
      end
    end
  end
end
