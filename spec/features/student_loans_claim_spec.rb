require "rails_helper"

RSpec.feature "Teacher Student Loan Repayments claims" do
  include StudentLoansHelper

  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }
  let!(:school) { create(:school, :student_loans_eligible) }

  [
    true,
    false
  ].each do |javascript_enabled|
    js_status = javascript_enabled ? "enabled" : "disabled"
    scenario "Teacher claims back student loan repayments with javascript #{js_status}", js: javascript_enabled do
      visit new_claim_path(StudentLoans.routing_name)

      skip_tid

      # Check we can't skip ahead pages in the journey
      visit claim_completion_path(StudentLoans.routing_name)
      expect(page).to have_current_path("/#{StudentLoans.routing_name}/existing-session")
      visit claim_path(StudentLoans.routing_name, "still-teaching")
      expect(page).to have_current_path("/#{StudentLoans.routing_name}/qts-year")
      visit claim_path(StudentLoans.routing_name, "leadership-position")
      expect(page).to have_current_path("/#{StudentLoans.routing_name}/qts-year")

      expect(page).to have_text(I18n.t("student_loans.questions.qts_award_year"))
      expect(page).to have_link(href: "mailto:#{I18n.t("student_loans.feedback_email")}")

      choose_qts_year
      claim = Claim.by_policy(StudentLoans).order(:created_at).last
      claim.update(details_check: true)

      expect(claim.eligibility.reload.qts_award_year).to eql("on_or_after_cut_off_date")

      expect(page).to have_text(claim_school_question)

      choose_school school
      expect(claim.eligibility.reload.claim_school).to eql school
      expect(page).to have_text(subjects_taught_question(school_name: school.name))

      check "Physics"
      click_on "Continue"
      expect(page).to have_text(I18n.t("student_loans.questions.employment_status"))

      choose_still_teaching("Yes, at #{school.name}")
      expect(claim.eligibility.reload.employment_status).to eql("claim_school")
      expect(claim.eligibility.current_school).to eql(school)

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
      expect(page).to have_text("For more details, you can read about payments and deductions when claiming back your student loan repayments")
      click_on "Continue"

      # - Personal details
      expect(page).to have_text(I18n.t("questions.personal_details"))
      expect(page).to have_text(I18n.t("questions.name"))

      fill_in "claim_first_name", with: "Russell"
      fill_in "claim_surname", with: "Wong"

      expect(page).to have_text(I18n.t("questions.date_of_birth"))

      fill_in "Day", with: "28"
      fill_in "Month", with: "2"
      fill_in "Year", with: "1988"

      expect(page).to have_text(I18n.t("questions.national_insurance_number"))

      fill_in "National Insurance number", with: "PX321499A"
      click_on "Continue"

      expect(claim.reload.first_name).to eql("Russell")
      expect(claim.reload.surname).to eql("Wong")
      expect(claim.reload.date_of_birth).to eq(Date.new(1988, 2, 28))
      expect(claim.reload.national_insurance_number).to eq("PX321499A")

      expect(page).to have_text(I18n.t("questions.address.home.title"))

      # Check we can't skip to pages if address not entered
      visit claim_path(StudentLoans.routing_name, "email-address")
      expect(page).to have_current_path("/#{StudentLoans.routing_name}/address")

      click_on "Back"

      expect(page).to have_link(href: claim_path(StudentLoans.routing_name, "address"))

      click_link(I18n.t("questions.address.home.link_to_manual_address"))

      expect(page).to have_text(I18n.t("questions.address.generic.title"))
      fill_in_address

      expect(claim.reload.address_line_1).to eql("123 Main Street")
      expect(claim.address_line_2).to eql("Downtown")
      expect(claim.address_line_3).to eql("Twin Peaks")
      expect(claim.address_line_4).to eql("Washington")
      expect(claim.postcode).to eql("M1 7HL")

      expect(page).to have_text(I18n.t("questions.email_address"))
      expect(page).to have_text(I18n.t("questions.email_address_hint1"))
      fill_in I18n.t("questions.email_address"), with: "name@example.tld"
      click_on "Continue"

      expect(claim.reload.email_address).to eq("name@example.tld")

      # - One time password
      expect(page).to have_text("Enter the 6-digit passcode")

      mail = ActionMailer::Base.deliveries.last
      otp_in_mail_sent = mail[:personalisation].decoded.scan(/\b[0-9]{6}\b/).first

      fill_in "claim_one_time_password", with: otp_in_mail_sent

      click_on "Confirm"

      # - Provide mobile number
      expect(page).to have_text(I18n.t("questions.provide_mobile_number"))

      choose "No"
      click_on "Continue"

      expect(claim.reload.provide_mobile_number).to eql false

      # - Mobile number
      expect(page).not_to have_text(I18n.t("questions.mobile_number"))
      expect(page).to have_text(I18n.t("questions.bank_or_building_society"))

      choose "Building society"
      click_on "Continue"

      expect(claim.reload.bank_or_building_society).to eq "building_society"

      expect(page).to have_text(I18n.t("questions.account_details", bank_or_building_society: claim.bank_or_building_society.humanize.downcase))
      expect(page).to have_text("Building society roll number")

      fill_in "Name on your account", with: "Jo Bloggs"
      fill_in "Sort code", with: "123456"
      fill_in "Account number", with: "87654321"
      fill_in "Building society roll number", with: "1234/123456789"
      click_on "Continue"

      expect(claim.reload.banking_name).to eq("Jo Bloggs")
      expect(claim.bank_sort_code).to eq("123456")
      expect(claim.bank_account_number).to eq("87654321")
      expect(claim.building_society_roll_number).to eq("1234/123456789")

      expect(page).to have_text(I18n.t("questions.payroll_gender"))
      choose "Male"
      click_on "Continue"

      expect(claim.reload.payroll_gender).to eq("male")

      expect(page).to have_text(I18n.t("questions.teacher_reference_number"))
      fill_in :claim_teacher_reference_number, with: "1234567"
      click_on "Continue"

      expect(claim.reload.teacher_reference_number).to eql("1234567")

      expect(page).to have_text(I18n.t("questions.has_student_loan"))

      answer_student_loan_plan_questions

      expect(claim.reload).to have_student_loan
      expect(claim.student_loan_country).to eq("england")
      expect(claim.student_loan_courses).to eq("one_course")
      expect(claim.student_loan_start_date).to eq(StudentLoan::BEFORE_1_SEPT_2012)
      expect(claim.student_loan_plan).to eq(StudentLoan::PLAN_1)

      # - Are you currently paying off your masters/doctoral loan
      expect(page).not_to have_text(I18n.t("questions.has_masters_and_or_doctoral_loan"))
      expect(claim.reload.has_masters_doctoral_loan).to be_nil

      # - Did you take out a postgraduate masters loan on or after 1 August 2016
      expect(page).to have_text(I18n.t("questions.postgraduate_masters_loan"))

      choose "Yes"
      click_on "Continue"

      expect(claim.reload.postgraduate_masters_loan).to eql true

      # - Did you take out a postgraduate doctoral loan on or after 1 August 2016
      expect(page).to have_text(I18n.t("questions.postgraduate_doctoral_loan"))

      choose "Yes"
      click_on "Continue"

      expect(claim.reload.postgraduate_doctoral_loan).to eql true

      expect(page).to have_text(student_loan_amount_question)
      fill_in student_loan_amount_question, with: "1100"
      click_on "Continue"

      expect(claim.eligibility.reload.student_loan_repayment_amount).to eql(1100.00)

      expect(page).to have_text("Check your answers before sending your application")

      stub_qualified_teaching_statuses_show(
        trn: claim.teacher_reference_number,
        params: {
          birthdate: claim.date_of_birth.to_s,
          nino: claim.national_insurance_number
        }
      )

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

      # Check we can't skip to pages in middle of page sequence after claim is submitted
      visit claim_path(StudentLoans.routing_name, "still-teaching")
      expect(page).to have_current_path("/#{StudentLoans.routing_name}/sign-in-or-continue")
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
        visit new_claim_path(StudentLoans.routing_name)
        skip_tid
        expect(page).to have_text(I18n.t("questions.qts_award_year"))
        expect(page).to have_link(href: "mailto:#{I18n.t("student_loans.feedback_email")}")

        choose_qts_year
        claim = Claim.by_policy(StudentLoans).order(:created_at).last

        expect(claim.eligibility.reload.qts_award_year).to eql("on_or_after_cut_off_date")

        expect(page).to have_text(claim_school_question)

        choose_school school
        expect(claim.eligibility.reload.claim_school).to eql school
        expect(page).to have_text(subjects_taught_question(school_name: school.name))

        check "Physics"
        click_on "Continue"
        expect(page).to have_text(I18n.t("student_loans.questions.employment_status"))

        choose_still_teaching("Yes, at #{school.name}")
        expect(claim.eligibility.reload.employment_status).to eql("claim_school")
        expect(claim.eligibility.current_school).to eql(school)

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
      end
    end
  end

  scenario "currently works at a different school to the claim school" do
    different_school = create(:school, :student_loans_eligible)
    claim = start_student_loans_claim

    choose_school school
    choose_subjects_taught

    choose_still_teaching("Yes, at another school")

    expect(claim.eligibility.reload.employment_status).to eql("different_school")

    fill_in :school_search, with: different_school.name
    click_on "Continue"

    choose different_school.name
    click_on "Continue"

    expect(claim.eligibility.reload.current_school).to eql different_school

    expect(page).to have_text(leadership_position_question)
  end
end
