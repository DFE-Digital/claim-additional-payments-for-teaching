require "rails_helper"

RSpec.feature "Ineligible Teacher Student Loan Repayments claims" do
  include OmniauthMockHelper
  include StudentLoansHelper

  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }
  let!(:school) { create(:school, :student_loans_eligible) }
  let!(:ineligible_school) { create(:school, :student_loans_ineligible) }
  let(:import_zero_amount_slc_data) { create(:student_loans_data, nino:, date_of_birth:, plan_type_of_deduction: 1, amount: 0) }
  let(:import_no_data_slc_data) { create(:student_loans_data, nino:, date_of_birth:, plan_type_of_deduction: nil, amount: 0) }
  let(:eligible_itt_years) { Journeys::AdditionalPaymentsForTeaching.selectable_itt_years_for_claim_year(journey_configuration.current_academic_year) }
  let(:academic_date) { Date.new(eligible_itt_years.first.start_year, 12, 1) }
  let(:itt_year) { AcademicYear.for(academic_date) }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1999-01-01" }
  let(:nino) { "AB123123A" }
  let(:eligible_dqt_body) do
    {
      qualified_teacher_status: {
        qts_date: academic_date.to_s
      }
    }
  end

  after do
    set_mock_auth(nil)
  end

  scenario "qualified before the first eligible QTS year" do
    journey_configuration.update!(current_academic_year: "2025/2026")

    visit new_claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)
    skip_tid
    choose_qts_year(:before_cut_off_date)
    session = Journeys::TeacherStudentLoanReimbursement::Session.last

    expect(session.answers.qts_award_year).to eql("before_cut_off_date")
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you completed your initial teacher training between the start of the 2014 to 2015 academic year and the end of the 2020 to 2021 academic year.")

    # Check we can go back and change the answer
    visit claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "qts-year")
    expect(page).to have_current_path("/#{Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME}/qts-year")

    choose_qts_year

    expect(page).to have_current_path("/#{Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME}/claim-school")
  end

  scenario "chooses an ineligible claim school" do
    start_student_loans_claim
    session = Journeys::TeacherStudentLoanReimbursement::Session.last
    choose_school ineligible_school

    expect(session.reload.answers.claim_school).to eq ineligible_school
    expect(page).to have_text("This school is not eligible")
    expect(page).to have_text("#{ineligible_school.name} is not an eligible school.")
  end

  scenario "chooses an ineligible current school" do
    start_student_loans_claim

    choose_school school
    choose_subjects_taught

    choose_still_teaching "Yes, at another school"

    choose_school ineligible_school

    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("#{ineligible_school.name}, where you are currently employed to teach, is not a state-funded secondary school.")
  end

  scenario "no longer teaching" do
    start_student_loans_claim
    session = Journeys::TeacherStudentLoanReimbursement::Session.last
    choose_school school
    choose_subjects_taught

    choose_still_teaching "No"

    expect(session.reload.answers.employment_status).to eq("no_school")
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you’re still employed to teach at a state-funded secondary school.")
  end

  scenario "did not teach an eligible subject" do
    start_student_loans_claim
    choose_school school

    check I18n.t("student_loans.forms.subjects_taught.answers.none_taught")
    click_on "Continue"

    session = Journeys::TeacherStudentLoanReimbursement::Session.last
    expect(session.answers.taught_eligible_subjects).to eq(false)
    expect(page).to have_text("You did not select an eligible subject")
    expect(page).to have_text("You can only get this payment if you taught one or more of the following subjects between #{Policies::StudentLoans.current_financial_year}:")
  end

  scenario "was in a leadership position and performed leadership duties for more than half of their time" do
    start_student_loans_claim
    choose_school school
    check "Biology"
    click_on "Continue"

    choose_still_teaching("Yes, at #{school.name}")

    choose "Yes"
    click_on "Continue"

    choose "Yes"
    click_on "Continue"

    session = Journeys::TeacherStudentLoanReimbursement::Session.last
    expect(session.answers.mostly_performed_leadership_duties?).to eq(true)
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you spent less than half your working hours performing leadership duties between #{Policies::StudentLoans.current_financial_year}.")
  end

  scenario "claimant made zero student loan repayments (Non-TID journey)" do
    import_zero_amount_slc_data

    start_student_loans_claim
    choose_school school

    check "Physics"
    click_on "Continue"

    choose_still_teaching("Yes, at #{school.name}")

    choose "Yes"
    click_on "Continue"

    choose "No"
    click_on "Continue"
    click_on "Continue"
    click_on "Continue"

    # - Personal details
    fill_in "First name", with: "Russell"
    fill_in "Last name", with: "Wong"

    fill_in "Day", with: Date.parse(date_of_birth).day
    fill_in "Month", with: Date.parse(date_of_birth).month
    fill_in "Year", with: Date.parse(date_of_birth).year

    fill_in "National Insurance number", with: nino
    click_on "Continue"

    expect(page).to have_text("Your student loan repayment amount is £0.00")
    expect(page).to have_text("you are not eligible to claim back any repayments")
  end

  scenario "claimant has no student loan (Non-TID journey)" do
    import_no_data_slc_data

    start_student_loans_claim
    choose_school school

    check "Physics"
    click_on "Continue"

    choose_still_teaching("Yes, at #{school.name}")

    choose "Yes"
    click_on "Continue"

    choose "No"
    click_on "Continue"
    click_on "Continue"
    click_on "Continue"

    # - Personal details
    fill_in "First name", with: "Russell"
    fill_in "Last name", with: "Wong"

    fill_in "Day", with: Date.parse(date_of_birth).day
    fill_in "Month", with: Date.parse(date_of_birth).month
    fill_in "Year", with: Date.parse(date_of_birth).year

    fill_in "National Insurance number", with: nino
    click_on "Continue"

    expect(page).to have_text("Your student loan repayment amount is £0.00")
    expect(page).to have_text("you are not eligible to claim back any repayments")
  end

  scenario "claimant made zero student loan repayments (TID journey)" do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:}, body: eligible_dqt_body)

    import_zero_amount_slc_data

    visit landing_page_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)

    # - Landing (start)
    click_on "Start now"
    click_on "Continue with DfE Identity"

    # - Teacher details page
    choose "Yes"
    click_on "Continue"

    # - Qualification details
    choose "Yes"
    click_on "Continue"

    # - Which school do you teach at
    choose_school school
    click_on "Continue"

    # - Select subject
    check "Physics"
    click_on "Continue"
    choose_still_teaching("Yes, at #{school.name}")

    #  - Are you still employed to teach at
    choose "Yes"
    click_on "Continue"

    #  - leadership-position question
    choose "No"
    click_on "Continue"

    #  - Eligibility confirmed
    click_on "Continue"

    # - information-provided page
    click_on "Continue"

    expect(page).to have_text("Your student loan repayment amount is £0.00")
    expect(page).to have_text("you are not eligible to claim back any repayments")
  end

  scenario "claimant has no student loan (TID journey)" do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_qualified_teaching_statuses_show(trn:, params: {birthdate: date_of_birth, nino:}, body: eligible_dqt_body)

    import_no_data_slc_data

    visit landing_page_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)

    # - Landing (start)
    click_on "Start now"
    click_on "Continue with DfE Identity"

    # - Teacher details page
    choose "Yes"
    click_on "Continue"

    # - Qualification details
    choose "Yes"
    click_on "Continue"

    # - Which school do you teach at
    choose_school school
    click_on "Continue"

    # - Select subject
    check "Physics"
    click_on "Continue"
    choose_still_teaching("Yes, at #{school.name}")

    #  - Are you still employed to teach at
    choose "Yes"
    click_on "Continue"

    #  - leadership-position question
    choose "No"
    click_on "Continue"

    #  - Eligibility confirmed
    click_on "Continue"

    # - information-provided page
    click_on "Continue"

    expect(page).to have_text("Your student loan repayment amount is £0.00")
    expect(page).to have_text("you are not eligible to claim back any repayments")
  end

  scenario "claimant can start a fresh claim after being told they are ineligible, by visiting the start page" do
    start_student_loans_claim
    choose_school ineligible_school
    expect(page).to have_text("This school is not eligible")

    visit new_claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)

    expect(page).to_not have_content("You have a claim in progress")

    skip_tid

    expect(page).to have_content("When did you complete your initial teacher training (ITT)?")
    expect(page).not_to have_css("input[checked]")
    choose_qts_year

    choose_school school

    expect(page).to have_text(subjects_taught_question(school_name: school.name))
  end
end
