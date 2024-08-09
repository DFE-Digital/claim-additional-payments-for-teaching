module Journeys
  module FurtherEducationPayments
    module Provider
      class VerifyClaimForm < Form
        attribute :declaration, :boolean

        validates :declaration, acceptance: true

        # validate claim not already verified

        delegate :claim, to: :answers

        def claim_reference
          claim.reference
        end

        def claimant_name
          claim.full_name
        end

        def claimant_date_of_birth
          claim.date_of_birth.strftime("%-d %B %Y")
        end

        def claimant_trn
          claim.eligibility.teacher_reference_number
        end

        def claim_date
          claim.created_at.to_date.strftime("%-d %B %Y")
        end

        def save
          return false unless valid?

          true
        end
      end
    end
  end
end
