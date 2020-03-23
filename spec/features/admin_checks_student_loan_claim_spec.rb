require "rails_helper"

RSpec.feature "Admin checking a Student Loans claim" do
  let(:user) { create(:dfe_signin_user) }

  let!(:claim) {
    create(
      :claim,
      :submitted,
      policy: StudentLoans,
      student_loan_plan: StudentLoan::PLAN_2,
      eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: "1987.65")
    )
  }

  before do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
  end

  scenario "service operator checks and approves a Student Loans claim" do
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    expect(page).to have_content("1. Qualifications")
    expect(page).to have_content("2. Employment")
    expect(page).to have_content("3. Student loan amount")
    expect(page).to have_content("4. Decision")

    click_on "Check qualification information"

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.qualifications"))
    expect(page).to have_content("Award year")
    expect(page).to have_content(claim.eligibility.qts_award_year_answer)

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "qualifications").passed?).to eq(true)

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.employment"))
    expect(page).to have_content("Current school")
    expect(page).to have_link(claim.eligibility.current_school.name)

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "employment").passed?).to eq(true)

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.student_loan_amount"))
    expect(page).to have_content("£1,987.65")
    expect(page).to have_content("Plan 2")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "student_loan_amount").passed?).to eq(true)

    expect(page).to have_content("Claim decision")

    choose "Approve"
    fill_in "Decision notes", with: "All checks passed!"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(claim.latest_decision).to be_approved
    expect(claim.latest_decision.created_by).to eq(user)
  end

  scenario "service operator can check a claim with matching details" do
    claim_with_matching_details = create(:claim, :submitted,
      teacher_reference_number: claim.teacher_reference_number)

    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    expect(page).to have_content("1. Qualifications")
    expect(page).to have_content("2. Employment")
    expect(page).to have_content("3. Student loan amount")
    expect(page).to have_content("4. Matching details")
    expect(page).to have_content("5. Decision")

    click_on I18n.t("admin.tasks.matching_details")

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.matching_details"))
    expect(page).to have_content(claim_with_matching_details.reference)
    expect(page).to have_content("Teacher reference number")

    choose "Yes"
    click_on "Save and continue"

    expect(claim.tasks.find_by!(name: "matching_details").passed?).to eq(true)

    expect(page).to have_content("Claim decision")
  end
end
