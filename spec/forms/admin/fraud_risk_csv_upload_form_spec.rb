require "rails_helper"

RSpec.describe Admin::FraudRiskCsvUploadForm, type: :model do
  describe "validations" do
    context "without a file" do
      it "is invalid" do
        form = described_class.new
        expect(form).not_to be_valid
        expect(form.errors[:file]).to include("CSV file is required")
      end
    end

    context "with an invalid csv" do
      it "is invalid" do
        file_path = Rails.root.join(
          "spec", "fixtures", "files", "fraud_risk_missing_headers.csv"
        )

        file = Rack::Test::UploadedFile.new(file_path)

        form = described_class.new(file: file)

        expect(form).not_to be_valid
        expect(form.errors[:base]).to include(
          "csv is missing required headers `field`, `value`"
        )
      end
    end

    context "with a missing value csv" do
      it "is invalid" do
        file_path = Rails.root.join(
          "spec", "fixtures", "files", "fraud_risk_missing_value.csv"
        )

        file = Rack::Test::UploadedFile.new(file_path)

        form = described_class.new(file: file)

        expect(form).not_to be_valid
        expect(form.errors[:base]).to include("'value' can't be blank")
      end
    end

    context "with an unsupported field" do
      it "is invalid" do
        file_path = Rails.root.join(
          "spec", "fixtures", "files", "fraud_risk_unknown_attribute.csv"
        )

        file = Rack::Test::UploadedFile.new(file_path)

        form = described_class.new(file: file)

        expect(form).not_to be_valid
        expect(form.errors[:base]).to include(
          "'test' is not a valid attribute - must be one of teacher_reference_number, national_insurance_number"
        )
      end
    end
  end

  describe "#save" do
    let(:file) do
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec", "fixtures", "files", "fraud_risk.csv")
      )
    end

    let(:form) { described_class.new(file: file) }

    it "creates risk indicator records for each row" do
      expect(form.save).to be true

      expect(RiskIndicator.count).to eq(2)

      expect(
        RiskIndicator.where(field: "teacher_reference_number").first.value
      ).to eq("1234567")

      expect(
        RiskIndicator.where(field: "national_insurance_number").first.value
      ).to eq("qq123456c")
    end

    it "doesn't duplicate existing risk indicator records" do
      RiskIndicator.create!(
        field: "teacher_reference_number",
        value: "1234567"
      )

      RiskIndicator.create!(
        field: "national_insurance_number",
        value: "qq123456c"
      )

      expect { form.save }.not_to change(RiskIndicator, :count)
    end

    it "removes risk indicators that are no longer in the CSV" do
      RiskIndicator.create!(
        field: "teacher_reference_number",
        value: "2234567"
      )

      RiskIndicator.create!(
        field: "national_insurance_number",
        value: "qq111111c"
      )

      _unchanged_risk_indicator = RiskIndicator.create!(
        field: "national_insurance_number",
        value: "qq123456c"
      )

      expect(form.save).to be true

      expect(
        RiskIndicator.where(
          field: "teacher_reference_number",
          value: "2234567"
        )
      ).to be_empty

      expect(
        RiskIndicator.where(
          field: "national_insurance_number",
          value: "qq111111c"
        )
      ).to be_empty

      expect(
        RiskIndicator.where(
          field: "national_insurance_number",
          value: "qq123456c"
        )
      ).to exist
    end

    it "adds a note to claims that are flagged" do
      claim_1 = create(:claim, national_insurance_number: "qq123456c")

      claim_2 = create(
        :claim,
        eligibility_attributes: {teacher_reference_number: "1234567"}
      )

      claim_3 = create(
        :claim,
        national_insurance_number: "qq123456c",
        eligibility_attributes: {teacher_reference_number: "1234567"}
      )

      form.save

      expect(claim_1.notes.by_label("fraud_risk").last.body).to eq(
        "This claim has been flagged as the national insurance number is " \
        "included on the fraud prevention list."
      )

      expect(claim_2.notes.by_label("fraud_risk").last.body).to eq(
        "This claim has been flagged as the teacher reference number is " \
        "included on the fraud prevention list."
      )

      expect(claim_3.notes.by_label("fraud_risk").last.body).to eq(
        "This claim has been flagged as the national insurance number and " \
        "teacher reference number are included on the fraud prevention list."
      )
    end

    it "doesn't add a note to claims that aren't flagged" do
      claim = create(
        :claim,
        national_insurance_number: "qq123456d",
        eligibility_attributes: {teacher_reference_number: "1234568"}
      )

      expect { form.save }.not_to change { claim.notes.count }
    end
  end
end
