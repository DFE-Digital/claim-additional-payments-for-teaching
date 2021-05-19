require "rails_helper"

RSpec.feature "Admin checking a claim missing a payroll gender" do
  before { @signed_in_user = sign_in_as_service_operator }

  scenario "service operator can add a payroll gender as part of the checking process" do
    claim = create(:claim, :submitted, policy: StudentLoans, payroll_gender: :dont_know)

    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    expect(page).to have_content("1. Identity confirmation")
    expect(page).to have_content("2. Qualifications")
    expect(page).to have_content("3. Employment")
    expect(page).to have_content("4. Student loan amount")
    expect(page).to have_content("5. Payroll gender")
    expect(page).to have_content("6. Decision")

    click_on I18n.t("admin.tasks.payroll_gender")

    expect(page).to have_content("What gender should be passed to payroll and HMRC?")

    click_on "Save and continue"

    expect(page).to have_content("Select male, female, or I don’t know")

    choose "Female"
    click_on "Save and continue"

    expect(claim.reload.payroll_gender).to eq("female")
    expect(claim.tasks.find_by!(name: "payroll_gender").passed?).to eq(true)

    expect(page).to have_content("Claim decision")

    choose "Approve"
    fill_in "Decision notes", with: "All checks passed!"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(claim.latest_decision).to be_approved
    expect(claim.latest_decision.created_by).to eq(@signed_in_user)
  end
end
