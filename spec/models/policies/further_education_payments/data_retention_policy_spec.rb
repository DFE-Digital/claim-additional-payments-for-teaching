require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::DataRetentionPolicy do
  it "has a policy for every attribute" do
    claim = create(:claim)
    eligibility = create(:further_education_payments_eligibility, claim: claim)

    eligibility.class.column_names.each do |attribute_name|
      expect(
        described_class::ELIGIBILITY_ATTRIBUTES.key?(attribute_name.to_sym)
      ).to(
        be(true),
        "Missing data retention policy for eligibility attribute: #{attribute_name}" \
        "\nUpdate #{described_class} to include this attribute."
      )
    end

    claim.class.column_names.each do |attribute_name|
      expect(
        described_class::CLAIM_ATTRIBUTES.key?(attribute_name.to_sym)
      ).to(
        be(true),
        "Missing data retention policy for claim attribute: #{attribute_name}" \
        "\nUpdate #{described_class} to include this attribute."
      )
    end
  end

  describe "scrubbing attributes" do
    let(:eligibility) do
      create(:further_education_payments_eligibility)
    end

    let(:claim) do
      create(
        :claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        eligibility: eligibility,
        academic_year: academic_year,
        address_line_1: "123 Example Street"
      )
    end

    before { described_class.new(claim).scrub! }

    around do |example|
      travel_to(DateTime.new(2025, 9, 1, 0, 0, 0)) do
        example.run
      end
    end

    describe "address_line_1" do
      context "when the claim is older than five academic years" do
        let(:academic_year) { AcademicYear.new(2020) }

        it "removes the address_line_1" do
          expect(claim.address_line_1).to be_nil
        end

        it "records the removal in presonal_data_removed" do
          expect(claim.presonal_data_removed).to include(
            {
              attribute: "address_line_1",
              removed_at: DateTime.new(2025, 9, 1, 0, 0, 0)
            }
          )
        end
      end

      context "when the claim is within five academic years" do
        let(:academic_year) { AcademicYear.current - 3 }

        it "does not remove the address_line_1" do
          expect(claim.address_line_1).to eq("123 Example Street")
        end
      end
    end
  end
end
