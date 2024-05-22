require "rails_helper"

RSpec.describe AddressForm, type: :model do
  subject(:form) { described_class.new(claim:, journey:, params:, journey_session:) }

  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:journey_session) { build(:student_loans_session) }
  let(:claim) { CurrentClaim.new(claims: [build(:claim, policy: Policies::StudentLoans)]) }
  let(:slug) { "address" }
  let(:params) { ActionController::Parameters.new({slug:, claim: claim_params}) }
  let(:claim_params) do
    {
      address_line_1: "123",
      address_line_2: "Main Street",
      address_line_3: "Some City",
      address_line_4: "",
      postcode: "PE11 3EW"
    }
  end

  it { is_expected.to be_a(Form) }

  describe "validations" do
    context "required address lines provided" do
      it { is_expected.to be_valid }
    end

    context "required address lines blank" do
      let(:claim_params) do
        {
          address_line_1: "",
          address_line_2: "",
          address_line_3: "",
          address_line_4: "",
          postcode: ""
        }
      end

      it "is invalid with presence errors" do
        is_expected.not_to be_valid

        expect(form.errors.size).to eq 4
        expect(form.errors[:address_line_1]).to eq([form.i18n_errors_path(:address_line_1_blank)])
        expect(form.errors[:address_line_2]).to eq([form.i18n_errors_path(:address_line_2_blank)])
        expect(form.errors[:address_line_3]).to eq([form.i18n_errors_path(:address_line_3_blank)])
        expect(form.errors[:postcode]).to eq([form.i18n_errors_path(:postcode_blank)])
      end
    end

    context "address lines too long" do
      let(:over_one_hundred_chars) { Array.new(101) { [("a".."z"), ("A".."Z"), ("0".."9")].map(&:to_a).flatten.sample }.join }
      let(:claim_params) do
        {
          address_line_1: over_one_hundred_chars,
          address_line_2: over_one_hundred_chars,
          address_line_3: over_one_hundred_chars,
          address_line_4: over_one_hundred_chars,
          postcode: "AB12 3CDXXXX"
        }
      end

      it "is invalid with too long errors" do
        is_expected.not_to be_valid

        expect(form.errors.size).to eq 6
        expect(form.errors[:address_line_1]).to eq([form.i18n_errors_path(:address_line_max_chars)])
        expect(form.errors[:address_line_2]).to eq([form.i18n_errors_path(:address_line_max_chars)])
        expect(form.errors[:address_line_3]).to eq([form.i18n_errors_path(:address_line_max_chars)])
        expect(form.errors[:address_line_4]).to eq([form.i18n_errors_path(:address_line_max_chars)])
        expect(form.errors[:postcode]).to contain_exactly(form.i18n_errors_path(:postcode_max_chars), form.i18n_errors_path(:postcode_format))
      end
    end

    context "address lines with format errors" do
      let(:claim_params) do
        {
          address_line_1: "#123",
          address_line_2: "Main $treet",
          address_line_3: "$ome City",
          address_line_4: "$som County",
          postcode: "XXX XXXX"
        }
      end

      it "is invalid with too format errors" do
        is_expected.not_to be_valid

        expect(form.errors.size).to eq 5
        expect(form.errors[:address_line_1]).to eq([form.i18n_errors_path(:address_format)])
        expect(form.errors[:address_line_2]).to eq([form.i18n_errors_path(:address_format)])
        expect(form.errors[:address_line_3]).to eq([form.i18n_errors_path(:address_format)])
        expect(form.errors[:address_line_4]).to eq([form.i18n_errors_path(:address_format)])
        expect(form.errors[:postcode]).to eq([form.i18n_errors_path(:postcode_format)])
      end
    end
  end

  describe "#save" do
    before do
      allow(form).to receive(:update!)
    end

    context "valid params" do
      context "all required address lines provided" do
        let(:expected_saved_attributes) do
          {
            "address_line_1" => "123",
            "address_line_2" => "Main Street",
            "address_line_3" => "Some City",
            "address_line_4" => "",
            "postcode" => "PE11 3EW"
          }
        end

        before { form.save }

        it { is_expected.to have_received(:update!).with(expected_saved_attributes) }
      end

      context "all address lines provided" do
        let(:claim_params) do
          {
            address_line_1: "123",
            address_line_2: "Main Street",
            address_line_3: "Some City",
            address_line_4: "Some County",
            postcode: "PE11 3EW"
          }
        end
        let(:expected_saved_attributes) do
          {
            "address_line_1" => "123",
            "address_line_2" => "Main Street",
            "address_line_3" => "Some City",
            "address_line_4" => "Some County",
            "postcode" => "PE11 3EW"
          }
        end

        before { form.save }

        it { is_expected.to have_received(:update!).with(expected_saved_attributes) }
      end
    end

    context "invalid params" do
      let(:claim_params) do
        {
          address_line_1: "",
          address_line_2: "",
          address_line_3: "",
          address_line_4: "",
          postcode: ""
        }
      end

      before { form.save }

      it { expect(form).not_to have_received(:update!) }
    end
  end
end
