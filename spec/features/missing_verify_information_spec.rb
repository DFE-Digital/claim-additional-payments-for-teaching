require "rails_helper"

RSpec.feature "Missing information from GOV.UK Verify" do
  scenario "Claimant is asked a payroll gender question when Verify doesn’t provide their gender" do
    claim = start_claim
    choose_qts_year
    choose_school schools(:penistone_grammar_school)
    choose_still_teaching
    check "Physics"
    click_on "Continue"
    choose "Yes"
    click_on "Continue"

    perform_verify_step("identity-verified-other-gender")

    expect(page).to have_text(I18n.t("tslr.questions.payroll_gender"))
    choose "Female"
    click_on "Continue"

    expect(claim.reload.payroll_gender).to eq("female")

    fill_in :claim_teacher_reference_number, with: "1234567"
    click_on "Continue"

    fill_in "National Insurance number", with: "QQ123456C"
    click_on "Continue"

    answer_student_loan_plan_questions

    fill_in I18n.t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name), with: "1100"
    click_on "Continue"

    fill_in I18n.t("tslr.questions.email_address"), with: "name@example.tld"
    click_on "Continue"

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
