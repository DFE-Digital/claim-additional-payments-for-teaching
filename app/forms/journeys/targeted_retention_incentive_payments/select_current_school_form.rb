module Journeys
  module TargetedRetentionIncentivePayments
    class SelectCurrentSchoolForm < ::SelectCurrentSchoolForm
      def save
        return false unless super

        journey_session.answers.update!(
          award_amount: Policies::TargetedRetentionIncentivePayments.award_amount(
            current_school
          )
        )
      end
    end
  end
end
