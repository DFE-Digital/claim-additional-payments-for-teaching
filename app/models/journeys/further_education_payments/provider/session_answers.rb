module Journeys
  module FurtherEducationPayments
    module Provider
      class SessionAnswers < Journeys::SessionAnswers
        attribute :claim_id, :string, pii: false
        attribute :declaration, :boolean, pii: false
        attribute :dfe_sign_in_uid, :string, pii: false
        attribute :dfe_sign_in_organisation_id, :string, pii: false
        attribute :dfe_sign_in_organisation_ukprn, :string, pii: false
        attribute :dfe_sign_in_organisation_name, :string, pii: true
        attribute :dfe_sign_in_service_access, :boolean, default: false, pii: false
        attribute :dfe_sign_in_role_codes, default: [], pii: false
        attribute :dfe_sign_in_first_name, :string, pii: true
        attribute :dfe_sign_in_last_name, :string, pii: true
        attribute :dfe_sign_in_email, :string, pii: true
        attribute :claim_started_verified, :boolean, pii: false

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
