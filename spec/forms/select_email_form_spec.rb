require "rails_helper"

RSpec.describe SelectEmailForm, type: :model do
  subject(:form) { described_class.new(journey_session:, journey:, params:) }

  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:journey_session) do
    create(
      :student_loans_session,
      answers: {
        teacher_id_user_info: {
          "email" => email_from_teacher_id
        }
      }
    )
  end
  let(:slug) { "select-email" }
  let(:params) { ActionController::Parameters.new({slug:, claim: claim_params}) }
  let(:claim_params) { {email_address_check: "false"} }
  let(:email_from_teacher_id) { "test@email.com" }

  def stub_email(email)
    allow_any_instance_of(journey::SessionAnswers).to(
      receive(:teacher_id_user_info).and_return({"email" => email})
    )
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

        stub_email("a" * (130 - 12) + "@example.com")
        is_expected.to be_invalid
        expect(form.errors[:email_address]).to eq([form.i18n_errors_path(:invalid_email)])
      end
    end
  end

  describe "#save" do
    context "valid params" do
      context "when the user selected to use the email address from Teacher ID" do
        let(:claim_params) { {email_address_check: "true"} }

        before { form.save }

        it "updates the session" do
          expect(journey_session.reload.answers.email_address).to(
            eq(email_from_teacher_id)
          )

          expect(journey_session.reload.answers.email_verified).to eq(true)

          expect(journey_session.reload.answers.email_address_check).to eq(true)
        end
      end

      context "when the user selected to provide a different email address" do
        let(:claim_params) { {email_address_check: "false"} }

        before { form.save }

        it "updates the session" do
          expect(journey_session.reload.answers.email_address).to eq(nil)
          expect(journey_session.reload.answers.email_verified).to eq(nil)
          expect(journey_session.reload.answers.email_address_check).to eq(false)
        end
      end
    end
  end
end
