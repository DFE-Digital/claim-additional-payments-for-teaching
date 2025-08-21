require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::ClaimPersonalDataScrubber do
  it_behaves_like(
    "a claim personal data scrubber",
    Policies::FurtherEducationPayments
  )

  it "stores claimant personal data for the full duration of the policy" do
    travel_to AcademicYear.current.start_of_autumn_term + 1.day

    claim = create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      first_name: "Edna",
      middle_name: "Marie",
      surname: "Krabappel",
      date_of_birth: Date.new(1970, 1, 1),
      address_line_1: "Flat 12",
      address_line_2: "82",
      address_line_3: "Evergreen Terrace",
      address_line_4: "Springfield",
      postcode: "AB12 3CD",
      national_insurance_number: "QQ123456C",
      mobile_number: "07123456789",
      hmrc_bank_validation_responses: [{code: 200, body: "Test response"}],
      payroll_gender: "female",
      eligibility_attributes: {
        teacher_reference_number: "1234567"
      }
    )

    create(:decision, :rejected, claim: claim)

    described_class.new.scrub_completed_claims

    claim.reload

    Policies::FurtherEducationPayments::PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD.each do |attribute|
      expect(claim.send(attribute)).to be_present
    end

    travel_to AcademicYear.current.start_of_autumn_term + 5.years - 1.day

    described_class.new.scrub_completed_claims

    claim.reload

    Policies::FurtherEducationPayments::PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD.each do |attribute|
      expect(claim.send(attribute)).to be_present
    end

    travel_to AcademicYear.current.start_of_autumn_term + 5.years

    described_class.new.scrub_completed_claims

    claim.reload

    Policies::FurtherEducationPayments::PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD.each do |attribute|
      expect(claim.send(attribute)).to be_blank
    end
  end
end
