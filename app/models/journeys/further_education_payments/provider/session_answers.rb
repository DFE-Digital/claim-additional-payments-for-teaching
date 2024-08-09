module Journeys
  module FurtherEducationPayments
    module Provider
      class SessionAnswers < Journeys::SessionAnswers
        attribute :claim_id, :string
        attribute :declaration, :boolean
        attribute :dfe_sign_in_uid, :string
        attribute :dfe_sign_in_organisation_ukprn, :string

        def claim
          @claim ||= Claim.includes(eligibility: :school).find(claim_id)
        end
      end
    end
  end
end
