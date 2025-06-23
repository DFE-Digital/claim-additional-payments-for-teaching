require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::ClaimPersonalDataScrubber do
  it_behaves_like(
    "a claim personal data scrubber",
    Policies::FurtherEducationPayments
  )

  it "removes claimant personal details and passport number from the eligibility" do
    last_academic_year = AcademicYear.previous.start_of_autumn_term.beginning_of_day

    claim = create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility_attributes: {
        claimant_date_of_birth: "1970-01-01",
        claimant_postcode: "AB12 3CD",
        claimant_national_insurance_number: "QQ123456C",
        claimant_passport_number: "123456789",
        passport_number: "987654321"
      }
    )

    create(
      :decision,
      :rejected,
      claim: claim,
      created_at: last_academic_year
    )

    described_class.new.scrub_completed_claims

    eligibility = claim.reload.eligibility

    expect(eligibility.claimant_date_of_birth).to be_nil
    expect(eligibility.claimant_postcode).to be_nil
    expect(eligibility.claimant_national_insurance_number).to be_nil
    expect(eligibility.claimant_passport_number).to be_nil
    expect(eligibility.passport_number).to be_nil
  end
end
