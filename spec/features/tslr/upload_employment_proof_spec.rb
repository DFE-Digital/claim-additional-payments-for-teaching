require "rails_helper"

RSpec.feature "TSLR upload employment proof" do
  include StudentLoansHelper

  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }
  let!(:school) { create(:school, :student_loans_eligible) }
  let(:imported_slc_data) { create(:student_loans_data, nino: "PX321499A", date_of_birth: "28/2/1988", plan_type_of_deduction: 1, amount: 1_100) }

  def answer_eligibility_questions
    visit new_claim_path(Journeys::TeacherStudentLoanReimbursement.routing_name)
    skip_tid

    choose_qts_year
    upload_employment_proof_multiple_with_delete

    expect(page).to have_text(claim_school_question)
    choose_school school

    expect(page).to have_text(subjects_taught_question(school_name: school.name))
    check "Physics"
    click_on "Continue"

    choose_still_teaching("Yes, at #{school.name}")

    expect(page).to have_text(leadership_position_question)
    choose "Yes"
    click_on "Continue"

    expect(page).to have_text(mostly_performed_leadership_duties_question)
    choose "No"
    click_on "Continue"
  end

  scenario "Teacher uploads multiple files, rejects one, deletes another, and check your answers shows the single remaining file" do
    imported_slc_data

    answer_eligibility_questions

    expect(page).to have_text("you can claim back the student loan repayments you made between #{Policies::StudentLoans.current_financial_year}.")
    click_on "Continue"

    expect(page).to have_text("How we will use the information you provide")
    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.personal_details"))
    fill_in "First name", with: "Russell"
    fill_in "Last name", with: "Wong"
    fill_in "Day", with: "28"
    fill_in "Month", with: "2"
    fill_in "Year", with: "1988"
    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    expect(page).to have_title(I18n.t("student_loans.questions.student_loan_amount"))
    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.address.home.title"))
    click_button I18n.t("questions.address.home.link_to_manual_address")
    fill_in_address

    fill_in I18n.t("questions.email_address"), with: "name@example.tld"
    click_on "Continue"

    mail = ActionMailer::Base.deliveries.last
    fill_in "claim-one-time-password-field", with: mail.personalisation[:one_time_password]
    click_on "Confirm"

    expect(page).to have_text(I18n.t("questions.provide_mobile_number"))
    choose "No"
    click_on "Continue"

    fill_in "Name on your account", with: "Russell Wong"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(page).to have_text(I18n.t("forms.gender.questions.payroll_gender"))
    choose "Male"
    click_on "Continue"

    fill_in "claim-teacher-reference-number-field", with: "1234567"
    click_on "Continue"

    expect(page).to have_text("Check your answers before sending your application")

    session = Journeys::TeacherStudentLoanReimbursement::Session.order(:created_at).last
    expect(session.answers.confirmed_employment_proof_blob_ids.count).to eq(1)
    expect(page).to have_text("Files")
    expect(page).to have_text("employment_proof3.pdf")
    expect(page).not_to have_text("employment_proof.pdf")
    expect(page).not_to have_text("employment_proof2.pdf")
  end
end
