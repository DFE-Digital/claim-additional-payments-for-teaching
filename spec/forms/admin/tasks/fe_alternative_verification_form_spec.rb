require "rails_helper"

RSpec.describe Admin::Tasks::FeAlternativeVerificationForm do
  subject { described_class.new claim: }

  describe "#data_table_rows" do
    context "when provider has not completed verification" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          :further_education
        )
      end

      it "returns awaiting response" do
        values = subject.data_table_rows.map { |row| row[2] }.uniq
        expect(values).to eql(["Awaiting provider response"])
      end
    end

    context "when provider has completed verification" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          :further_education,
          eligibility_attributes: {
            provider_verification_claimant_employed_by_college: true,
            provider_verification_claimant_date_of_birth: Date.new(1987, 2, 25),
            provider_verification_claimant_postcode: "EC1N 2TD",
            provider_verification_claimant_national_insurance_number: "AB123456C",
            provider_verification_claimant_bank_details_match: true,
            provider_verification_claimant_email: "work.email@example.com"
          }
        )
      end

      it "returns providers responses" do
        values = subject.data_table_rows.map { |row| row[2] }
        expected = [
          "Yes",
          "25 February 1987",
          "EC1N 2TD",
          "AB123456C",
          "Yes",
          "work.email@example.com"
        ]
        expect(values).to eql(expected)
      end
    end

    context "when claimant not employed by FE provider" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          :further_education,
          eligibility_attributes: {
            provider_verification_claimant_employed_by_college: false
          }
        )
      end

      it "returns mostly N/A answers" do
        values = subject.data_table_rows.map { |row| row[2] }
        expected = [
          "No",
          "N/A",
          "N/A",
          "N/A",
          "N/A",
          "N/A"
        ]
        expect(values).to eql(expected)
      end
    end
  end
end
