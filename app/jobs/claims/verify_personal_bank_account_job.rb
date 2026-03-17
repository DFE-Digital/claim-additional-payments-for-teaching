module Claims
  class VerifyPersonalBankAccountJob < ApplicationJob
    def perform(claim)
      return if claim.hmrc_bank_validation_succeeded
      return unless FeatureFlag.enabled?(:retry_bank_details)

      response = get_hmrc_response(claim)

      claim.hmrc_bank_validation_succeeded = !response.errored? && response.success?

      code = response.try(:code) || response.try(:status) || 1

      new_response_data = {
        code: code,
        body: response.safe_body
      }

      claim.hmrc_bank_validation_responses << new_response_data

      claim.save!
    end

    def priority
      10
    end

    private

    def get_hmrc_response(claim)
      Hmrc.client.verify_personal_bank_account(
        claim.bank_sort_code,
        claim.bank_account_number,
        claim.banking_name
      )
    end
  end
end
