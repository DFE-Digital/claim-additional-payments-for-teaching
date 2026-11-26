require "rails_helper"

RSpec.describe(
  Journeys::TeacherStudentLoanReimbursement::ConfirmNationalInsuranceNumberForm
) do
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }

  let(:updater) do
    Journeys::TeacherStudentLoanReimbursement::AnswersStudentLoansDetailsUpdater
  end

  let(:journey_session) do
    create(
      :student_loans_session,
      answers: {
        date_of_birth: Date.new(1980, 1, 1),
        teacher_auth_national_insurance_number: "AB123456C",
        national_insurance_number: national_insurance_number,
        student_loan_amount_seen: true
      }
    )
  end

  let(:national_insurance_number) { nil }

  let(:claim_params) { {} }

  subject(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: journey,
      params: ActionController::Parameters.new(claim: claim_params)
    )
  end

  before do
    create(
      :student_loans_data,
      nino: "AB123456C",
      date_of_birth: Date.new(1980, 1, 1),
      amount: 250
    )

    create(
      :student_loans_data,
      nino: "BB123456C",
      date_of_birth: Date.new(1980, 1, 1),
      amount: 100
    )
  end

  describe "#trs_national_insurance_number" do
    it "returns the NI number supplied by Teacher Auth" do
      expect(form.trs_national_insurance_number).to eq("AB123456C")
    end
  end

  describe "validations" do
    it "requires the claimant to confirm or reject the number" do
      expect(form).not_to be_valid

      expect(form.errors[:confirm_national_insurance_number]).to include(
        "Select yes if this is your National Insurance number"
      )
    end

    context "when the claimant rejects the number and enters an invalid one" do
      let(:claim_params) do
        {
          confirm_national_insurance_number: "false",
          national_insurance_number: "not-a-nino"
        }
      end

      it "is invalid" do
        expect(form).not_to be_valid

        expect(form.errors[:national_insurance_number]).to include(
          "Enter a National Insurance number in the correct format"
        )
      end
    end
  end

  describe "#save" do
    context "when the claimant confirms the number" do
      let(:claim_params) { {confirm_national_insurance_number: "true"} }

      it "uses the number from Teacher Auth and looks up loan data" do
        expect(form.save).to be true

        answers = journey_session.reload.answers

        expect(answers.confirm_national_insurance_number).to be true
        expect(answers.national_insurance_number).to eq("AB123456C")
        expect(answers.award_amount).to eq(250)
        expect(answers.student_loan_amount_seen).to be false
      end
    end

    context "when the claimant rejects the number and enters another" do
      let(:claim_params) do
        {
          confirm_national_insurance_number: "false",
          national_insurance_number: "bb 123456 c"
        }
      end

      it "uses the number they entered and looks up loan data" do
        expect(form.save).to be true

        answers = journey_session.reload.answers

        expect(answers.confirm_national_insurance_number).to be false
        expect(answers.national_insurance_number).to eq("BB123456C")
        expect(answers.teacher_auth_national_insurance_number).to eq(
          "AB123456C"
        )
        expect(answers.award_amount).to eq(100)
        expect(answers.student_loan_amount_seen).to be false
      end
    end

    context "when the NI number is unchanged" do
      let(:national_insurance_number) { "AB123456C" }
      let(:claim_params) { {confirm_national_insurance_number: "true"} }

      it "does not look up loan data again" do
        expect(updater).not_to receive(:call)

        expect(form.save).to be true

        expect(
          journey_session.reload.answers.student_loan_amount_seen
        ).to be true
      end
    end

    context "when the form is invalid" do
      let(:claim_params) do
        {
          confirm_national_insurance_number: "false",
          national_insurance_number: "not-a-nino"
        }
      end

      it "does not save or look up loan data" do
        expect(updater).not_to receive(:call)

        expect(form.save).to be false

        expect(
          journey_session.reload.answers.national_insurance_number
        ).to be_nil
      end
    end
  end
end
