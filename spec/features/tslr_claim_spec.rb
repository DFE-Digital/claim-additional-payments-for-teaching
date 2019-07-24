require "rails_helper"

RSpec.feature "Teacher Student Loan Repayments claims" do
  scenario "Teacher claims back student loan repayments" do
    claim = start_tslr_claim
    expect(page).to have_text(I18n.t("tslr.questions.qts_award_year"))

    choose_qts_year
    expect(claim.reload.qts_award_year).to eql("2014_2015")
    expect(page).to have_text(I18n.t("tslr.questions.claim_school"))

    choose_school schools(:penistone_grammar_school)
    expect(claim.reload.claim_school).to eql schools(:penistone_grammar_school)
    expect(page).to have_text(I18n.t("tslr.questions.employment_status"))

    choose_still_teaching
    expect(claim.reload.employment_status).to eql("claim_school")
    expect(claim.current_school).to eql(schools(:penistone_grammar_school))

    expect(page).to have_text(I18n.t("tslr.questions.subjects_taught"))
    check "Physics"
    click_on "Continue"

    expect(page).to have_text(I18n.t("tslr.questions.mostly_teaching_eligible_subjects", subjects: "Physics"))
    choose "Yes"
    click_on "Continue"

    expect(claim.reload.mostly_teaching_eligible_subjects).to eq(true)

    expect(page).to have_text("You are eligible to claim back student loan repayments")

    click_on "Skip GOV.UK Verify"

    expect(page).to have_text(I18n.t("tslr.questions.full_name"))

    fill_in I18n.t("tslr.questions.full_name"), with: "Margaret Honeycutt"
    click_on "Continue"

    expect(claim.reload.full_name).to eql("Margaret Honeycutt")

    expect(page).to have_text(I18n.t("tslr.questions.address"))

    fill_in :tslr_claim_address_line_1, with: "123 Main Street"
    fill_in :tslr_claim_address_line_2, with: "Downtown"
    fill_in "Town or city", with: "Twin Peaks"
    fill_in "County", with: "Washington"
    fill_in "Postcode", with: "M1 7HL"
    click_on "Continue"

    expect(claim.reload.address_line_1).to eql("123 Main Street")
    expect(claim.address_line_2).to eql("Downtown")
    expect(claim.address_line_3).to eql("Twin Peaks")
    expect(claim.address_line_4).to eql("Washington")
    expect(claim.postcode).to eql("M1 7HL")

    expect(page).to have_text(I18n.t("tslr.questions.date_of_birth"))
    fill_in "Day", with: "03"
    fill_in "Month", with: "7"
    fill_in "Year", with: "1990"
    click_on "Continue"

    expect(claim.reload.date_of_birth).to eq(Date.new(1990, 7, 3))

    expect(page).to have_text(I18n.t("tslr.questions.teacher_reference_number"))
    fill_in :tslr_claim_teacher_reference_number, with: "1234567"
    click_on "Continue"

    expect(claim.reload.teacher_reference_number).to eql("1234567")

    expect(page).to have_text(I18n.t("tslr.questions.national_insurance_number"))
    fill_in "National Insurance number", with: "QQ123456C"
    click_on "Continue"

    expect(claim.reload.national_insurance_number).to eq("QQ123456C")

    expect(page).to have_text(I18n.t("tslr.questions.has_student_loan"))
    choose("Yes")
    click_on "Continue"

    expect(claim.reload).to have_student_loan

    expect(page).to have_text(I18n.t("tslr.questions.student_loan_country"))
    choose("England")
    click_on "Continue"

    expect(claim.reload.student_loan_country).to eq("england")

    expect(page).to have_text(I18n.t("tslr.questions.student_loan_how_many_courses"))
    choose("1")
    click_on "Continue"

    expect(claim.reload.student_loan_courses).to eq("one_course")

    expect(page).to have_text(I18n.t("tslr.questions.student_loan_start_date.one_course"))
    choose I18n.t("tslr.answers.student_loan_start_date.one_course.before_first_september_2012")
    click_on "Continue"

    expect(claim.reload.student_loan_start_date).to eq(StudentLoans::BEFORE_1_SEPT_2012)
    expect(claim.student_loan_plan).to eq(StudentLoans::PLAN_1)

    expect(page).to have_text(I18n.t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name))
    fill_in I18n.t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name), with: "1100"
    click_on "Continue"

    expect(claim.reload.student_loan_repayment_amount).to eql(1100.00)

    expect(page).to have_text(I18n.t("tslr.questions.email_address"))
    expect(page).to have_text("We will only use your email address to update you about your claim.")
    fill_in I18n.t("tslr.questions.email_address"), with: "name@example.tld"
    click_on "Continue"

    expect(claim.reload.email_address).to eq("name@example.tld")

    expect(page).to have_text(I18n.t("tslr.questions.bank_details"))
    expect(page).to have_text("The account you want us to send your payment to.")
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(claim.reload.bank_sort_code).to eq("123456")
    expect(claim.reload.bank_account_number).to eq("87654321")

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
