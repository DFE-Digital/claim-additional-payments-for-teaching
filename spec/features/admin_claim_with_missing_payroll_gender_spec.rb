require "rails_helper"

RSpec.feature "Admin checking a claim missing a payroll gender" do
  let(:user) { create(:dfe_signin_user) }

  before do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
  end

  scenario "service operator can add a payroll gender as part of the checking process" do
    claim = create(:claim, :submitted, policy: StudentLoans, payroll_gender: :dont_know)

    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    expect(page).to have_content("1. Qualifications")
    expect(page).to have_content("2. Employment")
    expect(page).to have_content("3. Student loan amount")
    expect(page).to have_content("4. Payroll gender")
    expect(page).to have_content("5. Decision")

    click_on I18n.t("admin.tasks.payroll_gender")

    expect(page).to have_content("What gender should be passed to payroll and HMRC?")

    click_on "Save and continue"

    expect(page).to have_content("You must select a gender that will be passed to HMRC")

    choose "Female"
    click_on "Save and continue"

    expect(claim.reload.payroll_gender).to eq("female")
    expect(claim.tasks.find_by!(name: "payroll_gender").passed?).to eq(true)

    expect(page).to have_content("Claim decision")

    choose "Approve"
    fill_in "Decision notes", with: "All checks passed!"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(claim.decision).to be_approved
    expect(claim.decision.created_by).to eq(user)
  end
end
