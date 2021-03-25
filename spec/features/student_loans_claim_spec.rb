require "rails_helper"

RSpec.feature "Teacher Student Loan Repayments claims" do
  include StudentLoansHelper

  before { stub_geckoboard_dataset_update }

  [
    true,
    false
  ].each do |javascript_enabled|
    js_status = javascript_enabled ? "enabled" : "disabled"
    scenario "Teacher claims back student loan repayments with javascript #{js_status}", js: javascript_enabled do
      visit new_claim_path(StudentLoans.routing_name)
      expect(page).to have_text(I18n.t("questions.qts_award_year"))
      expect(page).to have_link(href: StudentLoans.feedback_url)

      choose_qts_year
      claim = Claim.order(:created_at).last

      expect(claim.eligibility.reload.qts_award_year).to eql("on_or_after_cut_off_date")

      expect(page).to have_text(claim_school_question)

      choose_school schools(:penistone_grammar_school)
      expect(claim.eligibility.reload.claim_school).to eql schools(:penistone_grammar_school)
      expect(page).to have_text(subjects_taught_question(school_name: schools(:penistone_grammar_school).name))

      check "Physics"
      click_on "Continue"
      expect(page).to have_text(I18n.t("student_loans.questions.employment_status"))

      choose_still_teaching
      expect(claim.eligibility.reload.employment_status).to eql("claim_school")
      expect(claim.eligibility.current_school).to eql(schools(:penistone_grammar_school))

      expect(claim.eligibility.reload.subjects_taught).to eq([:physics_taught])

      expect(page).to have_text(leadership_position_question)
      choose "Yes"
      click_on "Continue"

      expect(claim.eligibility.reload.had_leadership_position?).to eq(true)

      expect(page).to have_text(mostly_performed_leadership_duties_question)
      choose "No"
      click_on "Continue"

      expect(claim.eligibility.reload.mostly_performed_leadership_duties?).to eq(false)

      expect(page).to have_text("you can claim back the student loan repayments you made between #{StudentLoans.current_financial_year}.")
      click_on "Continue"

      expect(page).to have_text("How we will use the information you provide")
      click_on "Continue"

      expect(page).to have_text(I18n.t("questions.name"))
      fill_in "First name", with: "Edmund"
      fill_in "Middle names", with: "Percival"
      fill_in "Last name", with: "Hillary"
      click_on "Continue"

      expect(claim.reload.first_name).to eql("Edmund")
      expect(claim.middle_name).to eql("Percival")
      expect(claim.surname).to eql("Hillary")

      expect(page).to have_text(I18n.t("questions.address"))
      fill_in_address

      expect(claim.reload.address_line_1).to eql("123 Main Street")
      expect(claim.address_line_2).to eql("Downtown")
      expect(claim.address_line_3).to eql("Twin Peaks")
      expect(claim.address_line_4).to eql("Washington")
      expect(claim.postcode).to eql("M1 7HL")

      expect(page).to have_text(I18n.t("questions.date_of_birth"))
      fill_in "Day", with: "20"
      fill_in "Month", with: "7"
      fill_in "Year", with: "1919"
      click_on "Continue"

      expect(claim.reload.date_of_birth).to eq(Date.new(1919, 7, 20))

      expect(page).to have_text(I18n.t("questions.payroll_gender"))
      choose "Male"
      click_on "Continue"

      expect(claim.reload.payroll_gender).to eq("male")

      expect(page).to have_text(I18n.t("questions.teacher_reference_number"))
      fill_in :claim_teacher_reference_number, with: "1234567"
      click_on "Continue"

      expect(claim.reload.teacher_reference_number).to eql("1234567")

      expect(page).to have_text(I18n.t("questions.national_insurance_number"))
      fill_in "National Insurance number", with: "QQ123456C"
      click_on "Continue"

      expect(claim.reload.national_insurance_number).to eq("QQ123456C")

      expect(page).to have_text(I18n.t("questions.has_student_loan"))

      answer_student_loan_plan_questions

      expect(claim.reload).to have_student_loan
      expect(claim.student_loan_country).to eq("england")
      expect(claim.student_loan_courses).to eq("one_course")
      expect(claim.student_loan_start_date).to eq(StudentLoan::BEFORE_1_SEPT_2012)
      expect(claim.student_loan_plan).to eq(StudentLoan::PLAN_1)

      expect(page).to have_text(student_loan_amount_question)
      fill_in student_loan_amount_question, with: "1100"
      click_on "Continue"

      expect(claim.eligibility.reload.student_loan_repayment_amount).to eql(1100.00)

      expect(page).to have_text(I18n.t("questions.email_address"))
      expect(page).to have_text("We will only use your email address to update you about your claim, and to inform you about future opportunities to claim.")
      fill_in I18n.t("questions.email_address"), with: "name@example.tld"
      click_on "Continue"

      expect(claim.reload.email_address).to eq("name@example.tld")

      expect(page).to have_text(I18n.t("questions.bank_details"))
      expect(page).to have_text("The account you want us to send your payment to.")

      fill_in "Name on the account", with: "Jo Bloggs"
      fill_in "Sort code", with: "123456"
      fill_in "Account number", with: "87654321"
      fill_in "Building society roll number (if you have one)", with: "1234/123456789"
      click_on "Continue"

      expect(claim.reload.banking_name).to eq("Jo Bloggs")
      expect(claim.reload.bank_sort_code).to eq("123456")
      expect(claim.bank_account_number).to eq("87654321")
      expect(claim.building_society_roll_number).to eq("1234/123456789")

      expect(page).to have_text("Check your answers before sending your application")

      freeze_time do
        perform_enqueued_jobs do
          expect {
            click_on "Confirm and send"
          }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        expect(claim.reload.submitted_at).to eq(Time.zone.now)
      end

      expect(page).to have_text("Claim submitted")
      expect(page).to have_text(claim.reference)
      expect(page).to have_text(claim.email_address)
    end
  end

  scenario "currently works at a different school to the claim school" do
    claim = start_student_loans_claim

    choose_school schools(:penistone_grammar_school)
    choose_subjects_taught

    choose_still_teaching "Yes, at another school"

    expect(claim.eligibility.reload.employment_status).to eql("different_school")

    fill_in :school_search, with: "Hampstead"
    click_on "Search"

    choose "Hampstead School"
    click_on "Continue"

    expect(claim.eligibility.reload.current_school).to eql schools(:hampstead_school)

    expect(page).to have_text(leadership_position_question)
  end
end
