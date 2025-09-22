module Journeys
  module FurtherEducationPayments
    module Provider
      class SessionAnswers < Journeys::SessionAnswers
        class JsonType < ActiveModel::Type::Value
          def type
            :jsonb
          end

          def serialize(value)
            ActiveSupport::JSON.encode(value)
          end

          def cast(value)
            case value
            when Hash then value
            when String then ActiveSupport::JSON.decode(value)
            else fail "Unexpected value: #{value.inspect}"
            end
          end
        end

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
        attribute :verification, JsonType.new, default: {}, pii: true
        attribute :claimant_date_of_birth, :date, pii: true
        attribute :claimant_postcode, :string, pii: true
        attribute :claimant_national_insurance_number, :string, pii: true
        attribute :claimant_valid_passport, :boolean, pii: false
        attribute :claimant_passport_number, :string, pii: true
        attribute :claimant_identity_verified_at, :datetime, pii: false

        def claim
          @claim ||= Claim.includes(eligibility: :school).find(claim_id)
        end

        def dfe_sign_in_service_access?
          !!dfe_sign_in_service_access
        end

        def claim_verified?
          verification.present?
        end

        # We need to do this to get the base form to set existing verification
        # attributes from the session on the verification form.
        attribute :assertions_attributes, pii: false
        def assertions_attributes
          verification
            .fetch("assertions", [])
            .map(&:with_indifferent_access)
            .index_by(&:itself)
        end

        def identity_verification_required?
          Policies::FurtherEducationPayments
            .alternative_identity_verification_required?(claim)
        end
      end
    end
  end
end
