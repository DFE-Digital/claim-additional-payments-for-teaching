module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class SessionAnswers < Journeys::SessionAnswers
          attribute :claim_reference, :string, pii: false
          attribute :claimant_employed_by_nursery, :boolean, pii: false
          attribute :claimant_date_of_birth, :date, pii: true
          attribute :claimant_postcode, :string, pii: true
          attribute :claimant_national_insurance_number, :string, pii: true
          attribute :claimant_bank_details_match, :boolean, pii: false
          attribute :claimant_email, :string, pii: true
          attribute :claimant_employment_check_declaration, :boolean, pii: false
          attribute :alternative_idv_completed_at, :datetime, pii: false

          def claim
            @claim ||= Claim
              .by_policy(Policies::EarlyYearsPayments)
              .where(identity_confirmed_with_onelogin: false)
              .find_by(reference: claim_reference)
          end

          def nursery
            @nursery ||= claim.eligibility.eligible_ey_provider
          end

          def alternative_idv_completed!
            assign_attributes(alternative_idv_completed_at: Time.now.utc)

            session.save!

            claim.eligibility.update!(
              alternative_idv_claimant_employed_by_nursery: claimant_employed_by_nursery,
              alternative_idv_claimant_date_of_birth: claimant_date_of_birth,
              alternative_idv_claimant_postcode: claimant_postcode,
              alternative_idv_claimant_national_insurance_number: claimant_national_insurance_number,
              alternative_idv_claimant_bank_details_match: claimant_bank_details_match,
              alternative_idv_claimant_email: claimant_email,
              alternative_idv_claimant_employment_check_declaration: claimant_employment_check_declaration,
              alternative_idv_completed_at: alternative_idv_completed_at
            )
          end
        end
      end
    end
  end
end
