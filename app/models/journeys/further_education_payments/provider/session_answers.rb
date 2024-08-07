module Journeys
  module FurtherEducationPayments
    module Provider
      class SessionAnswers < Journeys::SessionAnswers
        # There's a lot of shared answers this journey's answers doesn't need
        # maybe split out another base class?
        attribute :claim_id, :string # UUID id of claim we're verifying
        attribute :dfe_sign_in_uid, :string
        attribute :dfe_sign_in_organisation_ukprn, :string
        attribute :dfe_sign_in_organisation_role_codes, default: []

        def claim
          @claim ||= Claim.includes(eligibility: :current_school).find(claim_id)
        end
      end
    end
  end
end
