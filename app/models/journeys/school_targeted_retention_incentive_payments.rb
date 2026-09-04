module Journeys
  module SchoolTargetedRetentionIncentivePayments
    extend Base
    extend self

    ROUTING_NAME = "targeted-retention-incentive-payments".freeze

    POLICIES = [Policies::TargetedRetentionIncentivePayments]
    FORMS = [
      CheckEligibilityIntroForm,
      HelloForm
    ]

    NONE_OF_THE_ABOVE_ACADEMIC_YEAR = "itt_academic_year_none"

    def requires_student_loan_details?
      true
    end

    def set_a_reminder?(itt_year)
      Policies::TargetedRetentionIncentivePayments.set_a_reminder?(itt_year)
    end

    def uses_reminders?
      true
    end

    def available?
      return false if Rails.env.test?

      FeatureFlag.enabled?(:new_stri)
    end
  end
end
