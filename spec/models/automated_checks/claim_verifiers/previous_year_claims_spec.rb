require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::PreviousYearClaims do
  describe "#perform" do
    it "associates the claims with previous year claims for the same policy" do
      current_claim = create(
        :claim,
        :submitted,
        academic_year: AcademicYear.current,
        policy: Policies::InternationalRelocationPayments,
        national_insurance_number: "AB123456C"
      )

      previous_year_claim_same_claimant_same_policy_1 = create(
        :claim,
        :submitted,
        academic_year: AcademicYear.previous,
        policy: Policies::InternationalRelocationPayments,
        national_insurance_number: "AB123456C"
      )

      previous_year_claim_same_claimant_same_policy_2 = create(
        :claim,
        :submitted,
        academic_year: AcademicYear.previous,
        policy: Policies::InternationalRelocationPayments,
        national_insurance_number: "AB123456C"
      )

      create(
        :claim,
        :submitted,
        academic_year: AcademicYear.previous,
        policy: Policies::InternationalRelocationPayments,
        national_insurance_number: "AB123456B"
      )

      create(
        :claim,
        :submitted,
        academic_year: AcademicYear.previous,
        policy: Policies::FurtherEducationPayments,
        national_insurance_number: "AB123456C"
      )

      create(
        :claim,
        :submitted,
        academic_year: AcademicYear.previous,
        policy: Policies::FurtherEducationPayments,
        national_insurance_number: "AB123456B"
      )

      create(
        :claim,
        :submitted,
        academic_year: AcademicYear.current,
        policy: Policies::InternationalRelocationPayments,
        national_insurance_number: "AB123456C"
      )

      create(
        :claim,
        :submitted,
        academic_year: AcademicYear.current,
        policy: Policies::FurtherEducationPayments,
        national_insurance_number: "AB123456C"
      )

      verifier = described_class.new(claim: current_claim)

      verifier.perform

      matching_claim_ids = current_claim.eligibility.previous_year_claim_ids

      expect(matching_claim_ids).to eq([
        previous_year_claim_same_claimant_same_policy_1.id,
        previous_year_claim_same_claimant_same_policy_2.id
      ])
    end
  end
end
