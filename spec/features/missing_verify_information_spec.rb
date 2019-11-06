require "rails_helper"

RSpec.feature "Missing information from GOV.UK Verify" do
  scenario "Claimant is asked a payroll gender question when Verify doesn’t provide their gender" do
    claim = start_claim
    choose_school schools(:penistone_grammar_school)
    choose_subjects_taught
    choose_still_teaching
    choose_leadership
    click_on "Continue"

    perform_verify_step("identity-verified-other-gender")
    expect(page).to have_text("This is your first name, middle name, surname, address, and date of birth from your digital identity")
    expect(page).to_not have_text("Gender")

    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.payroll_gender"))
    choose "Female"
    click_on "Continue"

    expect(claim.reload.payroll_gender).to eq("female")

    fill_in :claim_teacher_reference_number, with: "1234567"
    click_on "Continue"

    fill_in "National Insurance number", with: "QQ123456C"
    click_on "Continue"

    answer_student_loan_plan_questions

    fill_in I18n.t("student_loans.questions.student_loan_amount", claim_school_name: claim.eligibility.claim_school_name), with: "1100"
    click_on "Continue"

    fill_in I18n.t("questions.email_address"), with: "name@example.tld"
    click_on "Continue"

    fill_in "Name on the account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    freeze_time do
      perform_enqueued_jobs do
        expect {
          click_on "Confirm and send"
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      expect(claim.reload.submitted_at).to eq(Time.zone.now)
    end

    expect(page).to have_text("Claim submitted")
  end

  scenario "Claimant is asked an address question when Verify doesn’t provide their address" do
    claim = start_claim
    choose_school schools(:penistone_grammar_school)
    choose_subjects_taught
    choose_still_teaching
    choose_leadership
    click_on "Continue"

    perform_verify_step("identity-verified-no-address")
    expect(page).to have_text("This is your first name, surname, date of birth, and gender from your digital identity")
    expect(page).to_not have_text("Address")

    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.address"))
    fill_in_address

    expect(claim.reload.address_line_1).to eql("123 Main Street")
    expect(claim.address_line_2).to eql("Downtown")
    expect(claim.address_line_3).to eql("Twin Peaks")
    expect(claim.address_line_4).to eql("Washington")
    expect(claim.postcode).to eql("M1 7HL")

    fill_in :claim_teacher_reference_number, with: "1234567"
    click_on "Continue"

    fill_in "National Insurance number", with: "QQ123456C"
    click_on "Continue"

    answer_student_loan_plan_questions

    fill_in I18n.t("student_loans.questions.student_loan_amount", claim_school_name: claim.eligibility.claim_school_name), with: "1100"
    click_on "Continue"

    fill_in I18n.t("questions.email_address"), with: "name@example.tld"
    click_on "Continue"

    fill_in "Name on the account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    freeze_time do
      perform_enqueued_jobs do
        expect {
          click_on "Confirm and send"
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      expect(claim.reload.submitted_at).to eq(Time.zone.now)
    end

    expect(page).to have_text("Claim submitted")
  end
end
