require "rails_helper"

RSpec.feature "Admin checking a Student Loans claim" do
  let!(:claim) {
    create(
      :claim,
      :submitted,
      policy: StudentLoans,
      student_loan_plan: StudentLoan::PLAN_2,
      eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: "1987.65")
    )
  }

  before { @signed_in_user = sign_in_as_service_operator }

  scenario "service operator checks and approves a Student Loans claim" do
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    click_on I18n.t("admin.tasks.identity_confirmation")

    expect(page).to have_content("Did #{claim.full_name} submit the claim?")
    expect(page).to have_link("Next: Qualifications")
    expect(page).not_to have_link("Previous")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "identity_confirmation").passed?).to eq(true)

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.qualifications.title"))
    expect(page).to have_content("Award year")
    expect(page).to have_content(claim.eligibility.qts_award_year_answer)
    expect(page).to have_link("Next: Census subjects taught")
    expect(page).to have_link("Previous: Identity confirmation")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "qualifications").passed?).to eq(true)

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.census_subjects_taught.title"))
    expect(page).to have_content("Subjects taught Physics")
    expect(page).to have_link("Next: Employment")
    expect(page).to have_link("Previous: Qualifications")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "census_subjects_taught").passed?).to eq(true)

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.employment.title"))
    expect(page).to have_content("Current school")
    expect(page).to have_link(claim.eligibility.current_school.name)
    expect(page).to have_link("Next: Student loan amount")
    expect(page).to have_link("Previous: Census subjects taught")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "employment").passed?).to eq(true)

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.student_loan_amount.title"))
    expect(page).to have_content("£1,987.65")
    expect(page).to have_content("Plan 2")
    expect(page).to have_link("Next: Decision")
    expect(page).to have_link("Previous: Employment")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "student_loan_amount").passed?).to eq(true)

    expect(page).to have_content("Claim decision")
    expect(page).not_to have_link("Next")
    expect(page).to have_link("Previous: Student loan amount")

    choose "Approve"
    fill_in "Decision notes", with: "All checks passed!"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(claim.latest_decision).to be_approved
    expect(claim.latest_decision.created_by).to eq(@signed_in_user)
  end
end
