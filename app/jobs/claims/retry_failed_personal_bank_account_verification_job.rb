# Queue this up from the console
module Claims
  class RetryFailedPersonalBankAccountVerificationJob < ApplicationJob
    def perform
      date_range = DateTime.new(2026, 3, 2, 9, 0, 0)..DateTime.new(2026, 3, 3, 9, 0, 0)

      scope = Claim
        .where.not(submitted_at: nil)
        .where(created_at: date_range)
        .where(hmrc_bank_validation_succeeded: false)
        .order(created_at: :asc)

      scope.find_each.with_index do |claim, index|
        wait = index * 5

        Claims::VerifyPersonalBankAccountJob
          .set(wait: wait.seconds)
          .perform_later(claim)
      end
    end
  end
end
