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

          def claim
            @claim ||= Claim.find_by!(reference: claim_reference)
          end

          def nursery
            @nursery ||= claim.eligibility.eligible_ey_provider
          end
        end
      end
    end
  end
end
