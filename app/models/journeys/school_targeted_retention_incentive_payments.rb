module Journeys
  module SchoolTargetedRetentionIncentivePayments
    extend Base
    extend self

    ROUTING_NAME = "targeted-retention-incentive-payments".freeze

    POLICIES = [Policies::TargetedRetentionIncentivePayments].freeze
    FORMS = [
      CheckEligibilityIntroForm,
      HelloForm,
      CheckYourAnswersForm,
      ConfirmationForm
    ].freeze

    def available?
      FeatureFlag.enabled?(:new_stri)
    end

    def set_a_reminder?(itt_year)
      false
    end
  end
end
