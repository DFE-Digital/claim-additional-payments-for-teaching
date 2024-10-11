require "rails_helper"

RSpec.feature "Teacher Student Loan Repayments claims" do
  include StudentLoansHelper

  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }
  let!(:school) { create(:school, :student_loans_eligible) }
  let(:imported_slc_data) { create(:student_loans_data, nino: "PX321499A", date_of_birth: "28/2/1988", plan_type_of_deduction: 1, amount: 1_100) }

  def answer_eligibility_questions_and_fill_in_personal_details
    visit new_claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)

    skip_tid

    # Check we can't skip ahead pages in the journey
    visit claim_confirmation_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)
    expect(page).to have_current_path("/#{Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME}/existing-session")
    visit claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "still-teaching")
    expect(page).to have_current_path("/#{Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME}/qts-year")
    visit claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "leadership-position")
    expect(page).to have_current_path("/#{Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME}/qts-year")

    expect(page).to have_text(I18n.t("student_loans.forms.qts_year.questions.qts_award_year"))
    expect(page).to have_link(href: "mailto:#{I18n.t("student_loans.feedback_email")}")

    choose_qts_year
    session = Journeys::TeacherStudentLoanReimbursement::Session.order(:created_at).last

    expect(session.reload.answers.qts_award_year).to eql("on_or_after_cut_off_date")

    expect(page).to have_text(claim_school_question)

    choose_school school
    expect(session.reload.answers.claim_school).to eql school
    expect(page).to have_text(subjects_taught_question(school_name: school.name))

    check "Physics"
    click_on "Continue"
    expect(page).to have_text(I18n.t("student_loans.forms.still_teaching.questions.claim_school"))

    choose_still_teaching("Yes, at #{school.name}")
    expect(session.reload.answers.employment_status).to eql("claim_school")
    expect(session.answers.current_school).to eql(school)

    expect(session.reload.answers.subjects_taught).to eq([:physics_taught])

    expect(page).to have_text(leadership_position_question)
    choose "Yes"
    click_on "Continue"

    expect(session.reload.answers.had_leadership_position?).to eq(true)

    expect(page).to have_text(mostly_performed_leadership_duties_question)
    choose "No"
    click_on "Continue"

    expect(session.reload.answers.mostly_performed_leadership_duties?).to eq(false)

    expect(page).to have_text("you can claim back the student loan repayments you made between #{Policies::StudentLoans.current_financial_year}.")
    click_on "Continue"

    expect(page).to have_text("How we will use the information you provide")
    expect(page).to have_text("For more details, you can read about payments and deductions when claiming back your student loan repayments")
    click_on "Continue"

    # - Personal details
    expect(page).to have_text(I18n.t("questions.personal_details"))
    expect(page).to have_text(I18n.t("questions.name"))

    fill_in "First name", with: "Russell"
    fill_in "Last name", with: "Wong"

    expect(page).to have_text(I18n.t("questions.date_of_birth"))

    fill_in "Day", with: "28"
    fill_in "Month", with: "2"
    fill_in "Year", with: "1988"

    expect(page).to have_text(I18n.t("questions.national_insurance_number"))

    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    session.reload
    expect(session.answers.first_name).to eql("Russell")
    expect(session.answers.surname).to eql("Wong")
    expect(session.answers.date_of_birth).to eq(Date.new(1988, 2, 28))
    expect(session.answers.national_insurance_number).to eq("PX321499A")
  end

  def fill_in_remaining_personal_details_and_submit
    session = Journeys::TeacherStudentLoanReimbursement::Session.order(:created_at).last

    expect(page).to have_text(I18n.t("questions.address.home.title"))

    # Check we can't skip to pages if address not entered
    visit claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "email-address")
    expect(page).to have_current_path("/#{Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME}/address")

    click_on "Back"

    expect(page).to have_link(href: claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "address"))

    click_link(I18n.t("questions.address.home.link_to_manual_address"))

    expect(page).to have_text(I18n.t("forms.address.questions.your_address"))
    fill_in_address

    session.reload
    answers = session.answers
    expect(answers.address_line_1).to eql("123 Main Street")
    expect(answers.address_line_2).to eql("Downtown")
    expect(answers.address_line_3).to eql("Twin Peaks")
    expect(answers.address_line_4).to eql("Washington")
    expect(answers.postcode).to eql("M1 7HL")

    expect(page).to have_text(I18n.t("forms.email_address.label"))
    expect(page).to have_text(I18n.t("forms.email_address.hint1"))
    fill_in I18n.t("questions.email_address"), with: "name@example.tld"
    click_on "Continue"

    expect(session.reload.answers.email_address).to eq("name@example.tld")

    # - One time password
    expect(page).to have_text("Enter the 6-digit passcode")

    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail[:personalisation].decoded.scan(/\b[0-9]{6}\b/).first

    fill_in "claim-one-time-password-field", with: otp_in_mail_sent

    click_on "Confirm"

    # - Provide mobile number
    expect(page).to have_text(I18n.t("questions.provide_mobile_number"))
    choose "No"
    click_on "Continue"

    expect(session.reload.answers.provide_mobile_number).to eql false

    # - Mobile number
    expect(page).not_to have_text(I18n.t("questions.mobile_number"))

    expect(page).to have_text("Enter your personal bank account details")

    fill_in "Name on your account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    session.reload
    answers = session.answers
    expect(answers.banking_name).to eq("Jo Bloggs")
    expect(answers.bank_sort_code).to eq("123456")
    expect(answers.bank_account_number).to eq("87654321")

    expect(page).to have_text(I18n.t("forms.gender.questions.payroll_gender"))
    choose "Male"
    click_on "Continue"

    expect(session.reload.answers.payroll_gender).to eq("male")

    expect(page).to have_text(I18n.t("forms.teacher_reference_number.questions.teacher_reference_number"))
    fill_in "claim-teacher-reference-number-field", with: "1234567"
    click_on "Continue"

    expect(session.reload.answers.teacher_reference_number).to eql("1234567")

    expect(page).to have_text("Check your answers before sending your application")

    stub_qualified_teaching_statuses_show(
      trn: session.answers.teacher_reference_number,
      params: {
        birthdate: answers.date_of_birth.to_s,
        nino: answers.national_insurance_number
      }
    )

    freeze_time do
      perform_enqueued_jobs do
        expect {
          click_on "Confirm and send"
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      submitted_claim = Claim.by_policy(Policies::StudentLoans).order(:created_at).last
      expect(submitted_claim.submitted_at).to eq(Time.zone.now)
      expect(page).to have_text("Claim submitted")
      expect(page).to have_text(submitted_claim.reference)
      expect(page).to have_text(submitted_claim.email_address)
    end

    # Check we can't skip to pages in middle of page sequence after claim is submitted
    visit claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "still-teaching")
    expect(page).to have_current_path("/#{Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME}/sign-in-or-continue")
  end

  [
    true,
    false
  ].each do |javascript_enabled|
    js_status = javascript_enabled ? "enabled" : "disabled"
    scenario "Teacher claims back student loan repayments with javascript #{js_status} (SLC data present)", js: javascript_enabled do
      imported_slc_data

      answer_eligibility_questions_and_fill_in_personal_details

      # - Student loan amount details
      expect(page).to have_title(I18n.t("student_loans.questions.student_loan_amount"))
      click_on "Continue"

      journey_session = Journeys::TeacherStudentLoanReimbursement::Session.order(:created_at).last
      answers = journey_session.answers

      expect(answers).to have_student_loan
      expect(answers.student_loan_repayment_amount).to eql(1_100)
      expect(answers.student_loan_plan).to eq(StudentLoan::PLAN_1)

      fill_in_remaining_personal_details_and_submit

      claim = Claim.submitted.order(:created_at).last
      expect(claim.submitted_using_slc_data).to eql(true)
    end

    scenario "Teacher claims back student loan repayments with javascript #{js_status} (no SLC data present)", js: javascript_enabled do
      answer_eligibility_questions_and_fill_in_personal_details

      # - Student loan amount details
      expect(page).to have_title(I18n.t("student_loans.questions.student_loan_amount"))
      click_on "Continue"

      journey_session = Journeys::TeacherStudentLoanReimbursement::Session.order(:created_at).last
      answers = journey_session.answers

      expect(answers).not_to have_student_loan
      expect(answers.student_loan_repayment_amount).to eql(0)
      expect(answers.student_loan_plan).to be nil

      fill_in_remaining_personal_details_and_submit
    end
  end

  [
    2019,
    2025,
    2031
  ].each do |academic_year|
    context "in academic year #{academic_year}" do
      let!(:journey_configuration) { create(:journey_configuration, :student_loans, current_academic_year: AcademicYear.new(academic_year)) }

      scenario "Teacher claims back student loan repayments" do
        visit new_claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)
        skip_tid
        expect(page).to have_text(I18n.t("student_loans.forms.qts_year.questions.qts_award_year"))
        expect(page).to have_link(href: "mailto:#{I18n.t("student_loans.feedback_email")}")

        choose_qts_year
        session = Journeys::TeacherStudentLoanReimbursement::Session.order(:created_at).last

        expect(session.reload.answers.qts_award_year).to eql("on_or_after_cut_off_date")

        expect(page).to have_text(claim_school_question)

        choose_school school
        expect(session.reload.answers.claim_school).to eql school
        expect(page).to have_text(subjects_taught_question(school_name: school.name))

        check "Physics"
        click_on "Continue"
        expect(page).to have_text(I18n.t("student_loans.forms.still_teaching.questions.claim_school"))

        choose_still_teaching("Yes, at #{school.name}")
        expect(session.reload.answers.employment_status).to eql("claim_school")
        expect(session.answers.current_school).to eql(school)

        expect(session.reload.answers.subjects_taught).to eq([:physics_taught])

        expect(page).to have_text(leadership_position_question)
        choose "Yes"
        click_on "Continue"

        expect(session.reload.answers.had_leadership_position?).to eq(true)

        expect(page).to have_text(mostly_performed_leadership_duties_question)
        choose "No"
        click_on "Continue"

        expect(session.reload.answers.mostly_performed_leadership_duties?).to eq(false)
        expect(page).to have_text("you can claim back the student loan repayments you made between #{Policies::StudentLoans.current_financial_year}.")
      end
    end
  end

  scenario "currently works at a different school to the claim school" do
    different_school = create(:school, :student_loans_eligible)
    start_student_loans_claim
    session = Journeys::TeacherStudentLoanReimbursement::Session.order(:created_at).last

    choose_school school
    choose_subjects_taught

    choose_still_teaching("Yes, at another school")

    expect(session.reload.answers.employment_status).to eql("different_school")

    fill_in :school_search, with: different_school.name
    click_on "Continue"

    choose different_school.name
    click_on "Continue"

    expect(session.reload.answers.current_school).to eql different_school

    expect(page).to have_text(leadership_position_question)
  end
end
