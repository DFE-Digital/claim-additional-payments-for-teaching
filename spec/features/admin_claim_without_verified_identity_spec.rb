require "rails_helper"

RSpec.feature "Admin checking a claim without a verified identity" do
  let(:user) { create(:dfe_signin_user) }

  before do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
  end

  scenario "the service operator can do a manual identity check and approve the claim" do
    unverified_claim = create(:claim, :unverified)

    click_on "View claims"
    find("a[href='#{admin_claim_tasks_path(unverified_claim)}']").click

    expect(page).to have_content("4. Identity confirmation")

    click_on I18n.t("admin.tasks.identity_confirmation")

    expect(page).to have_content(I18n.t("student_loans.admin.task_questions.identity_confirmation", name: unverified_claim.full_name))
    expect(page).to have_content(unverified_claim.eligibility.current_school.name)
    expect(page).to have_content(unverified_claim.eligibility.current_school.phone_number)

    choose "Yes"
    click_on "Save and continue"

    expect(unverified_claim.tasks.find_by!(name: "identity_confirmation").passed?).to eq(true)

    choose "Approve"
    fill_in "Decision notes", with: "Identity confirmed via phone call"
    click_on "Confirm decision"

    expect(unverified_claim.latest_decision.created_by).to eq(user)
    expect(unverified_claim.latest_decision.notes).to eq("Identity confirmed via phone call")
  end
end
