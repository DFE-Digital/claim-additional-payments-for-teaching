module Policies
  module FurtherEducationPayments
    include BasePolicy
    extend self

    OTHER_CLAIMABLE_POLICIES = []
    ELIGIBILITY_MATCHING_ATTRIBUTES = [["teacher_reference_number"]].freeze

    # Percentage of claims to QA
    MIN_QA_THRESHOLD = 10

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::ProviderVerification
    ]

    # Options shown to admins when rejecting a claim
    ADMIN_DECISION_REJECTED_REASONS = [
      # FIXME RL: this `placeholder` is required to make the
      # `spec/models/policies/further_education_payments/claim_personal_data_scrubber_spec.rb`
      # test pass. Once we add a real rejection reason we can remove this
      # placeholder. Figured this was better than removing the test!
      :placeholder
    ]

    # TODO: This is needed once the reply-to email address has been added to Gov Notify
    def notify_reply_to_id
      nil
    end

    def verification_due_date_for_claim(claim)
      (claim.created_at + 2.weeks).to_date
    end

    def duplicate_claim?(claim)
      Claim::MatchingAttributeFinder.new(claim).matching_claims.exists?
    end
  end
end
