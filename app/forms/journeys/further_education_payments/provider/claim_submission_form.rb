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
          if answers.identity_verification_required?
            return false unless answers.claimant_identity_verified_at.present?
          end

          answers.verification.present?
        end

        def save!
          raise ActiveRecord::RecordInvalid unless valid?

          claim = answers.claim

          ApplicationRecord.transaction do
            claim.update!(verified_at: DateTime.now)

            claim.eligibility.update!(
              verification: answers.verification,
              claimant_date_of_birth: answers.claimant_date_of_birth,
              claimant_postcode: answers.claimant_postcode,
              claimant_national_insurance_number: answers.claimant_national_insurance_number,
              claimant_valid_passport: answers.claimant_valid_passport,
              claimant_passport_number: answers.claimant_passport_number,
              claimant_identity_verified_at: answers.claimant_identity_verified_at
            )
          end

          ClaimVerifierJob.perform_later(claim)

          true
        end

        private

        attr_reader :answers
      end
    end
  end
end
