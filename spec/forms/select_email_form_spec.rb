require "rails_helper"

RSpec.describe SelectEmailForm, type: :model do
  subject(:form) { described_class.new(claim:, journey:, params:) }

  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:claim) { CurrentClaim.new(claims: [build(:claim, policy: Policies::StudentLoans)]) }
  let(:slug) { "select-email" }
  let(:params) { ActionController::Parameters.new({slug:, claim: claim_params}) }
  let(:claim_params) { {email_address_check: "false"} }
  let(:email_from_teacher_id) { "test@email.com" }

  def stub_email(email)
    allow(claim).to receive(:teacher_id_user_info).and_return({"email" => email})
  end

  before { stub_email(email_from_teacher_id) }

  it { is_expected.to be_a(Form) }

  describe "validations" do
    context "email_address_check" do
      it "cannot be nil" do
        form.email_address_check = nil

        is_expected.to be_invalid
        expect(form.errors[:email_address_check]).to eq([form.i18n_errors_path(:select_email)])
      end

      it "can be true or false" do
        form.email_address_check = true
        is_expected.to be_valid

        form.email_address_check = false
        is_expected.to be_valid
      end
    end

    context "email_address" do
      before do
        form.email_address_check = true
      end

      it "validates presence" do
        stub_email("test@email.com")
        is_expected.to be_valid

        stub_email(nil)
        is_expected.to be_invalid
        expect(form.errors[:email_address]).to eq([form.i18n_errors_path(:invalid_email)])
      end

      it "validates format and length" do
        stub_email("test@invalid//email.com")
        is_expected.to be_invalid
        expect(form.errors[:email_address]).to eq([form.i18n_errors_path(:invalid_email)])

        stub_email("a" * 245 + "@example.com") # 257 chars
        is_expected.to be_invalid
        expect(form.errors[:email_address]).to eq([form.i18n_errors_path(:invalid_email)])
      end
    end
  end

  describe "#save" do
    before do
      allow(form).to receive(:update!)
    end

    context "valid params" do
      context "when the user selected to use the email address from Teacher ID" do
        let(:claim_params) { {email_address_check: "true"} }
        let(:expected_saved_attributes) do
          {
            "email_address_check" => true,
            "email_address" => email_from_teacher_id,
            "email_verified" => true
          }
        end

        before { form.save }

        it { is_expected.to have_received(:update!).with(expected_saved_attributes) }
      end

      context "when the user selected to provide a different email address" do
        let(:claim_params) { {email_address_check: "false"} }
        let(:expected_saved_attributes) do
          {
            "email_address_check" => false,
            "email_address" => nil,
            "email_verified" => nil
          }
        end

        before { form.save }

        it { is_expected.to have_received(:update!).with(expected_saved_attributes) }
      end
    end

    context "invalid params" do
      let(:claim_params) { {email_address_check: nil} }

      before { form.save }

      it { expect(form).not_to have_received(:update!) }
    end
  end
end
