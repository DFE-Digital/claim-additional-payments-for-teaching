module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class CheckYourAnswersForm < Form
      def save
        claim = Claim.new(
          policy: Policies::TargetedRetentionIncentivePayments,
          academic_year: journey.configuration.current_academic_year,
          eligibility:,
          first_name: journey_session.answers.first_name,
          surname: journey_session.answers.surname,
          date_of_birth: journey_session.answers.date_of_birth,
          email_address: journey_session.answers.email_address,
          submitted_at: Time.zone.now
        )

        claim.assign_new_reference
        claim.started_at = journey_session.created_at
        claim.save!

        session[:submitted_claim_id] = claim.id

        true
      end

      private

      def eligibility
        Policies::TargetedRetentionIncentivePayments::Eligibility.new
      end
    end
  end
end
