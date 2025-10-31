module Journeys
  module TargetedRetentionIncentivePayments
    class SelectCurrentSchoolForm < ::SelectCurrentSchoolForm
      def save
        return false unless super

        journey_session.answers.assign_attributes(
          award_amount: Policies::TargetedRetentionIncentivePayments.award_amount(
            current_school
          )
        )
        journey_session.save!

        true
      end
    end
  end
end
