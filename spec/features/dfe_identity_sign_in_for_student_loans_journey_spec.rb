require "rails_helper"

RSpec.feature "Teacher Identity Sign in for TSLR" do
  include OmniauthMockHelper
  include StudentLoansHelper

  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }
  let!(:school) { create(:school, :student_loans_eligible) }
  let(:current_academic_year) { journey_configuration.current_academic_year }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }

  after do
    set_mock_auth(nil)
  end

  scenario "Teacher makes claim for 'Student Loans' by logging in with teacher_id and selects yes to details confirm" do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})

    visit landing_page_path(Journeys::TeacherStudentLoanReimbursement.routing_name)

    # - Landing (start)
    expect(page).to have_text(I18n.t("student_loans.landing_page"))
    click_on "Start now"

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text(I18n.t("questions.check_and_confirm_details"))
    expect(page).to have_text(I18n.t("questions.details_correct"))

    choose "Yes"
    click_on "Continue"
    expect(page).to have_text(I18n.t("student_loans.forms.qts_year.questions.qts_award_year"))

    choose_qts_year
    expect(page).to have_text(claim_school_question)

    choose_school school
    expect(page).to have_text(subjects_taught_question(school_name: school.name))

    check "Physics"
    click_on "Continue"
    expect(page).to have_text(I18n.t("student_loans.forms.still_teaching.questions.claim_school"))

    choose_still_teaching("Yes, at #{school.name}")
    expect(page).to have_text(leadership_position_question)

    choose "Yes"
    click_on "Continue"
    expect(page).to have_text(mostly_performed_leadership_duties_question)

    choose "No"
    click_on "Continue"

    expect(page).to have_text("you can claim back the student loan repayments you made between #{Policies::StudentLoans.current_financial_year}.")
    click_on "Continue"

    expect(page).to have_text("How we will use the information you provide")
    expect(page).to have_text("For more details, you can read about payments and deductions when claiming back your student loan repayments")
    click_on "Continue"

    # - Personal details - skipped as TID data all provided for
    expect(page).not_to have_text(I18n.t("questions.personal_details"))

    # check the teacher_id_user_info details are saved to the session
    journey_session = Journeys::TeacherStudentLoanReimbursement::Session.last
    answers = journey_session.answers
    expect(answers.teacher_id_user_info).to eq({
      "trn" => "1234567",
      "birthdate" => date_of_birth,
      "given_name" => "Kelsie",
      "family_name" => "Oberbrunner",
      "ni_number" => nino,
      "phone_number" => "01234567890",
      "trn_match_ni_number" => "True",
      "email" => "kelsie.oberbrunner@example.com",
      "email_verified" => ""
    })

    # check the user_info details from teacher id are saved to the claim
    expect(answers.first_name).to eq("Kelsie")
    expect(answers.surname).to eq("Oberbrunner")
    expect(answers.date_of_birth).to eq(Date.parse(date_of_birth))
    expect(answers.national_insurance_number).to eq(nino)
    expect(answers.teacher_reference_number).to eq("1234567")
    expect(answers.logged_in_with_tid?).to eq(true)
    expect(answers.details_check).to eq(true)
    expect(answers.qts_award_year).to eql("on_or_after_cut_off_date")
    expect(answers.claim_school).to eql school
    expect(answers.employment_status).to eql("claim_school")
    expect(answers.current_school).to eql(school)
    expect(answers.subjects_taught).to eq([:physics_taught])
    expect(answers.had_leadership_position?).to eq(true)
    expect(answers.mostly_performed_leadership_duties?).to eq(false)
  end

  scenario "Teacher makes claim for 'Student Loans' by logging in with teacher_id and selects no to details confirm" do
    set_mock_auth(trn, {date_of_birth:, nino:})

    visit landing_page_path(Journeys::TeacherStudentLoanReimbursement.routing_name)

    # - Landing (start)
    expect(page).to have_text(I18n.t("student_loans.landing_page"))
    click_on "Start now"

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text(I18n.t("questions.check_and_confirm_details"))
    expect(page).to have_text(I18n.t("questions.details_correct"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text("You cannot use your DfE Identity account with this service")
    expect(page).to have_text("You can continue to complete an application to check your eligibility and apply for a payment.")

    click_on "Continue"

    expect(page).to have_text(I18n.t("student_loans.forms.qts_year.questions.qts_award_year"))

    # check the teacher_id_user_info details are saved to the session
    journey_session = Journeys::TeacherStudentLoanReimbursement::Session.last
    answers = journey_session.answers
    expect(answers.teacher_id_user_info).to eq({
      "trn" => "1234567",
      "birthdate" => date_of_birth,
      "given_name" => "Kelsie",
      "family_name" => "Oberbrunner",
      "ni_number" => nino,
      "phone_number" => "01234567890",
      "trn_match_ni_number" => "True",
      "email" => "kelsie.oberbrunner@example.com",
      "email_verified" => ""
    })

    # check the user_info details from teacher id are not saved to the sesssion
    expect(answers.first_name).to eq("")
    expect(answers.surname).to eq("")
    expect(answers.date_of_birth).to eq(nil)
    expect(answers.national_insurance_number).to eq("")
    expect(answers.teacher_reference_number).to eq("")
    expect(answers.logged_in_with_tid?).to eq(false)
    expect(answers.details_check).to eq(false)
  end

  scenario "Teacher makes claim for 'Student Loans' selects not to log in with teacher_id" do
    visit landing_page_path(Journeys::TeacherStudentLoanReimbursement.routing_name)

    # - Landing (start)
    expect(page).to have_text(I18n.t("student_loans.landing_page"))
    click_on "Start now"

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    expect(page).to have_text(I18n.t("student_loans.forms.qts_year.questions.qts_award_year"))

    # check the teacher_id_user_info details are not saved to the claim
    session = Journeys::TeacherStudentLoanReimbursement::Session.last
    answers = session.answers
    expect(answers.teacher_id_user_info).to eq({})

    # check the user_info details from teacher id are not saved to the claim
    expect(answers.first_name).to eq("")
    expect(answers.surname).to eq("")
    # expect(answers.date_of_birth).to eq(nil)
    # expect(answers.national_insurance_number).to eq("")
    # expect(answers.teacher_reference_number).to eq("")
    # expect(answers.logged_in_with_tid?).to eq(nil)
    # expect(answers.details_check).to eq(nil)
  end

  scenario "When user is logged in with Teacher ID and NINO is not supplied" do
    set_mock_auth(trn, {date_of_birth:, nino: nil})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino: ""})

    visit landing_page_path(Journeys::TeacherStudentLoanReimbursement.routing_name)
    click_on "Start now"
    click_on "Continue with DfE Identity"
    choose "Yes"
    click_on "Continue"
    choose_qts_year
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
    expect(page).to have_text(I18n.t("questions.personal_details"))

    # - not shown
    expect(page).not_to have_text(I18n.t("questions.name"))
    expect(page).not_to have_text(I18n.t("questions.date_of_birth"))

    # - shown
    expect(page).to have_text(I18n.t("questions.national_insurance_number"))

    updated_nino = "PX321499A"

    fill_in "National Insurance number", with: updated_nino
    click_on "Continue"

    # check the teacher_id_user_info details are saved to the session
    session = Journeys::TeacherStudentLoanReimbursement::Session.last
    answers = session.answers
    expect(answers.teacher_id_user_info).to eq({
      "trn" => "1234567",
      "birthdate" => date_of_birth,
      "given_name" => "Kelsie",
      "family_name" => "Oberbrunner",
      "ni_number" => "",
      "phone_number" => "01234567890",
      "trn_match_ni_number" => "True",
      "email" => "kelsie.oberbrunner@example.com",
      "email_verified" => ""
    })

    # check the user_info details from teacher id are saved to the claim
    expect(answers.first_name).to eq("Kelsie")
    expect(answers.surname).to eq("Oberbrunner")
    expect(answers.date_of_birth).to eq(Date.parse(date_of_birth))
    expect(answers.national_insurance_number).to eq(updated_nino)
    expect(answers.teacher_reference_number).to eq("1234567")
    expect(answers.logged_in_with_tid?).to eq(true)
    expect(answers.details_check).to eq(true)
    expect(answers.qts_award_year).to eql("on_or_after_cut_off_date")
    expect(answers.claim_school).to eql school
    expect(answers.employment_status).to eql("claim_school")
    expect(answers.current_school).to eql(school)
    expect(answers.subjects_taught).to eq([:physics_taught])
    expect(answers.had_leadership_position?).to eq(true)
    expect(answers.mostly_performed_leadership_duties?).to eq(false)
  end
end
