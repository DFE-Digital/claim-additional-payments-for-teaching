require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::NationalInsuranceNumberForm do
  it "saves the missing NI number and refreshes loan data without changing identity details" do
    journey_session = create(
      :student_loans_session,
      answers: {
        date_of_birth: Date.new(1980, 1, 1),
        national_insurance_number: nil,
        student_loan_amount_seen: true
      }
    )

    create(
      :student_loans_data,
      nino: "AB123456C",
      date_of_birth: Date.new(1980, 1, 1),
      amount: 250
    )

    form = described_class.new(
      journey: Journeys::TeacherStudentLoanReimbursement,
      journey_session: journey_session,
      params: ActionController::Parameters.new(
        claim: {
          national_insurance_number: "ab 123456 c",
          first_name: "Walter",
          surname: "Smith",
          "date_of_birth(1i)": "1990"
        }
      )
    )

    expect(form.save).to be true

    answers = journey_session.reload.answers

    expect(answers.national_insurance_number).to eq "AB123456C"
    expect(answers.award_amount).to eq 250
    expect(answers.student_loan_amount_seen).to be false
  end

  it "does not save or look up loan data for an invalid NI number" do
    journey_session = create(:student_loans_session)
    form = described_class.new(
      journey: Journeys::TeacherStudentLoanReimbursement,
      journey_session: journey_session,
      params: ActionController::Parameters.new(
        claim: {
          national_insurance_number: "invalid"
        }
      )
    )
    expect(
      Journeys::TeacherStudentLoanReimbursement::AnswersStudentLoansDetailsUpdater
    ).not_to receive(:call)

    expect(form.save).to be false
    expect(form.errors[:national_insurance_number]).to be_present
  end
end
