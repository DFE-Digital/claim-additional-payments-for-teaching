# Required to get page sequence to think this is a "normal" journey
module Journeys
  module FurtherEducationPayments
    module Provider
      class ClaimSubmissionForm
        def initialize(journey_session:)
          @journey_session = journey_session
          @answers = journey_session.answers
        end

        def valid?
          answers.verification.present?
        end

        def save!
          raise ActiveRecord::RecordInvalid unless valid?

          claim = answers.claim

          ApplicationRecord.transaction do
            claim.update!(verified_at: DateTime.now)

            claim.eligibility.update!(verification: answers.verification)
          end

          ClaimMailer
            .further_education_payment_provider_confirmation_email(claim)
            .deliver_later

          ClaimVerifierJob.perform_later(claim)

          true
        end

        private

        attr_reader :answers
      end
    end
  end
end
