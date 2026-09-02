module Admin
  module Claims
    class HmrcValidationJob < ApplicationJob
      TIMEOUT_SECONDS = 5

      def perform(claim)
        response = Hmrc.client.verify_personal_bank_account(
          claim.bank_sort_code,
          claim.bank_account_number,
          claim.banking_name,
          timeout: TIMEOUT_SECONDS
        )

        record_response(claim, code: response.status, body: response.safe_body)
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed
        record_response(
          claim,
          code: 504,
          body: "HMRC bank validation request timed out"
        )
      end

      private

      def record_response(claim, code:, body:)
        hmrc_bank_validation_responses = claim.hmrc_bank_validation_responses

        hmrc_bank_validation_responses << {
          code: code,
          body: body
        }

        claim.update!(
          hmrc_bank_validation_responses: hmrc_bank_validation_responses
        )
      end
    end
  end
end
