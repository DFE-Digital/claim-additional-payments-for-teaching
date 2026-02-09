require "rails_helper"

RSpec.describe Admin::ClaimantFlagsCsvUploadForm do
  describe "validating the CSV" do
    let(:file) { StringIO.new(data) }

    let(:admin) { create(:dfe_signin_user) }

    let(:form) { described_class.new({file: file, admin: admin}) }

    subject { form.tap(&:validate).errors.full_messages }

    context "when not all rows have a valid policy" do
      let(:data) do
        <<~CSV
          policy,identification_attribute,identification_value,reason,suggested_action
          FurtherEducationPayments,national_insurance_number,AB123456C,clawback,check with manager
          NotAPolicy,national_insurance_number,AB123456C,clawback,check with manager
        CSV
      end

      it { is_expected.to include("File Row 2: Invalid policy 'NotAPolicy'") }
    end

    context "when not all rows have a valid identification_attribute" do
      let(:data) do
        <<~CSV
          policy,identification_attribute,identification_value,reason,suggested_action
          FurtherEducationPayments,national_insurance_number,AB123456C,clawback,check with manager
          FurtherEducationPayments,height,AB123456C,clawback,check with manager
          EarlyYearsPayments,national_insurance_number,AB123456C,clawback,check with manager
        CSV
      end

      it do
        is_expected.to include(
          "File Row 2: Invalid identification attribute 'height'"
        )
      end
    end

    context "when not all rows have a valid reason" do
      let(:data) do
        <<~CSV
          policy,identification_attribute,identification_value,reason,suggested_action
          FurtherEducationPayments,national_insurance_number,AB123456C,clawback,check with manager
          FurtherEducationPayments,national_insurance_number,AB123456C,clawback,check with manager
          EarlyYearsPayments,national_insurance_number,AB123456C,not_a_reason,check with manager
        CSV
      end

      it do
        is_expected.to include("File Row 3: Invalid reason 'not_a_reason'")
      end
    end
  end

  describe "#save" do
    context "when valid" do
      it "creates ClaimantFlag records" do
        file_path = Rails.root.join(
          "spec", "fixtures", "files", "claimant_flagging.csv"
        )

        file = Rack::Test::UploadedFile.new(file_path)

        admin = create(:dfe_signin_user)

        form = described_class.new({file: file, admin: admin})

        expect { form.save }.to change(ClaimantFlag, :count).by(3)

        flag_1 = ClaimantFlag.find_by!(
          identification_attribute: "national_insurance_number",
          identification_value: "AB123456C"
        )

        flag_2 = ClaimantFlag.find_by!(
          identification_attribute: "national_insurance_number",
          identification_value: "AB123456A"
        )

        flag_3 = ClaimantFlag.find_by!(
          identification_attribute: "national_insurance_number",
          identification_value: "AB123456Z"
        )

        expect(flag_1.policy).to eq("FurtherEducationPayments")
        expect(flag_1.identification_attribute).to eq("national_insurance_number")
        expect(flag_1.identification_value).to eq("ab123456c")
        expect(flag_1.reason).to eq("clawback")
        expect(flag_1.suggested_action).to eq "check with manager"

        expect(flag_2.policy).to eq("FurtherEducationPayments")
        expect(flag_2.identification_attribute).to eq("national_insurance_number")
        expect(flag_2.identification_value).to eq("ab123456a")
        expect(flag_2.reason).to eq("clawback")
        expect(flag_2.suggested_action).to eq "check with manager"

        expect(flag_3.policy).to eq("EarlyYearsPayments")
        expect(flag_3.identification_attribute).to eq("national_insurance_number")
        expect(flag_3.identification_value).to eq("ab123456z")
        expect(flag_3.reason).to eq("clawback")
        expect(flag_3.suggested_action).to eq nil
      end
    end
  end
end
