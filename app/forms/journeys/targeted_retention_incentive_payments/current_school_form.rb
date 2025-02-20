module Journeys
  module TargetedRetentionIncentivePayments
    class CurrentSchoolForm < ::CurrentSchoolForm
      def save
        return false unless super

        journey_session.answers.assign_attributes(
          award_amount: Policies::TargetedRetentionIncentivePayments.award_amount(
            answers.current_school
          )
        )
        journey_session.save!

        true
      end
    end
  end
end
