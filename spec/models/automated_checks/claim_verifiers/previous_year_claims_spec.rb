require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::PreviousYearClaims do
  describe "#perform" do
    it "associates the claims with previous year claims for the same policy" do
      current_claim = create(
        :claim,
        :submitted,
        academic_year: AcademicYear.current,
        policy: Policies::InternationalRelocationPayments,
        national_insurance_number: "QQ123456C"
      )

      previous_year_claim_same_claimant_same_policy_1 = create(
        :claim,
        :submitted,
        academic_year: AcademicYear.previous,
        policy: Policies::InternationalRelocationPayments,
        national_insurance_number: "QQ123456C"
      )

      previous_year_claim_same_claimant_same_policy_2 = create(
        :claim,
        :submitted,
        academic_year: AcademicYear.previous,
        policy: Policies::InternationalRelocationPayments,
        national_insurance_number: "QQ123456C"
      )

      create(
        :claim,
        :submitted,
        academic_year: AcademicYear.previous,
        policy: Policies::InternationalRelocationPayments,
        national_insurance_number: "QQ123456B"
      )

      create(
        :claim,
        :submitted,
        academic_year: AcademicYear.previous,
        policy: Policies::FurtherEducationPayments,
        national_insurance_number: "QQ123456C"
      )

      create(
        :claim,
        :submitted,
        academic_year: AcademicYear.previous,
        policy: Policies::FurtherEducationPayments,
        national_insurance_number: "QQ123456B"
      )

      create(
        :claim,
        :submitted,
        academic_year: AcademicYear.current,
        policy: Policies::InternationalRelocationPayments,
        national_insurance_number: "QQ123456C"
      )

      create(
        :claim,
        :submitted,
        academic_year: AcademicYear.current,
        policy: Policies::FurtherEducationPayments,
        national_insurance_number: "QQ123456C"
      )

      verifier = described_class.new(claim: current_claim)

      verifier.perform

      matches = Claims::Match.where(source_claim: current_claim)

      expect(matches.count).to eq(2)

      expect(matches.pluck(:matching_attributes)).to eq([
        %w[national_insurance_number],
        %w[national_insurance_number]
      ])

      expect(matches.pluck(:matching_claim_id)).to eq([
        previous_year_claim_same_claimant_same_policy_1.id,
        previous_year_claim_same_claimant_same_policy_2.id
      ])
    end
  end
end
