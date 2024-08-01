module Policies
  module InternationalRelocationPayments
    include BasePolicy
    extend self

    ELIGIBILITY_MATCHING_ATTRIBUTES = [["passport_number"]].freeze
    OTHER_CLAIMABLE_POLICIES = []

    # Percentage of claims to QA
    MIN_QA_THRESHOLD = 100

    # Options shown to admins when rejecting a claim
    ADMIN_DECISION_REJECTED_REASONS = [
      :duplicate,
      :ineligible_school,
      :invalid_bank_details,
      :ineligible_visa_or_entry_date,
      :ineligible_employment_terms,
      :no_response_from_school,
      :suspected_fraud,
      :information_mismatch_new_details_needed
    ]

    # NOTE RL: currently IRP only has a single reply to address, so notify
    # doesn't show the address id
    def notify_reply_to_id
      nil
    end

    def award_amount
      5_000
    end
  end
end
