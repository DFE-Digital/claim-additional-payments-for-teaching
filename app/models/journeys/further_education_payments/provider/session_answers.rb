module Journeys
  module FurtherEducationPayments
    module Provider
      class SessionAnswers < Journeys::SessionAnswers
        attribute :claim_id, :string
        attribute :declaration, :boolean
        attribute :dfe_sign_in_uid, :string
        attribute :dfe_sign_in_organisation_id, :string
        attribute :dfe_sign_in_organisation_ukprn, :string
        attribute :dfe_sign_in_service_access, :boolean, default: false
        attribute :dfe_sign_in_role_codes, default: []

        def claim
          @claim ||= Claim.includes(eligibility: :school).find(claim_id)
        end

        def dfe_sign_in_service_access?
          !!dfe_sign_in_service_access
        end
      end
    end
  end
end