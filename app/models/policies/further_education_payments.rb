module Policies
  module FurtherEducationPayments
    include BasePolicy
    extend self

    OTHER_CLAIMABLE_POLICIES = []
    ELIGIBILITY_MATCHING_ATTRIBUTES = [["teacher_reference_number"]].freeze

    # Percentage of claims to QA
    MIN_QA_THRESHOLD = 0

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::Identity,
      AutomatedChecks::ClaimVerifiers::ProviderVerification,
      AutomatedChecks::ClaimVerifiers::Employment
    ]

    # Options shown to admins when rejecting a claim
    ADMIN_DECISION_REJECTED_REASONS = [
      :no_teaching_responsibilities,
      :no_eligible_contract_of_employment,
      :works_less_than_2_point_5_hours_per_week,
      :has_worked_in_further_education_for_more_than_5_years,
      :ineligible_subject_or_courses,
      :insufficient_time_spent_teaching_eligibble_students,
      :duplicate_claim,
      :no_response,
      :other
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

    def auto_pass_identity_confirmation_task(claim)
      claim.identity_confirmed_with_onelogin? ? :pass : :fail
    end
  end
end
