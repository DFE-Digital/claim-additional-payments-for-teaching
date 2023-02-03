require "rails_helper"

RSpec.feature "Admin checking a claim's payroll details" do
  before do
    create(:policy_configuration, :student_loans)
    @signed_in_user = sign_in_as_service_operator

    # Normally run on submission but not in factory
    AutomatedChecks::ClaimVerifiers::PayrollDetails.new(admin_user: nil, claim: claim).perform
  end

  context "when bank details validated during submission" do
    let!(:claim) { create(:claim, :submitted, :bank_details_validated) }

    scenario "does not show the payroll details task" do
      visit admin_claims_path
      find("a[href='#{admin_claim_tasks_path(claim)}']").click

      expect(page).not_to have_content("Payroll details")
      expect(page).not_to have_content I18n.t("admin.tasks.payroll_details")
    end
  end

  context "when bank details not validated during submission" do
    let!(:claim) { create(:claim, :submitted, :bank_details_not_validated) }

    scenario "shows the payroll details task" do
      visit admin_claims_path
      find("a[href='#{admin_claim_tasks_path(claim)}']").click

      expect(page).to have_content("Payroll details")
      expect(page).to have_content I18n.t("admin.tasks.payroll_details")

      expect(page.find(".app-task-list__item.payroll_details")).to have_text("No match")

      click_on I18n.t("admin.tasks.payroll_details")

      expect(page).to have_content I18n.t("student_loans.admin.task_questions.payroll_details.title", bank_or_building_society: I18n.t("admin.#{claim.bank_or_building_society}"))

      # Choosing 'No' should not mark the task as failed
      choose "No"
      click_on "Save and continue"

      expect(claim.tasks.find_by!(name: "payroll_details").reload.passed).to be_nil

      click_link "Back"

      expect(page.find(".app-task-list__item.payroll_details")).to have_text("No match")

      click_on I18n.t("admin.tasks.payroll_details")

      # Choosing 'Yes' should mark the task as passed
      choose "Yes"
      click_on "Save and continue"

      expect(claim.tasks.find_by!(name: "payroll_details").reload.passed).to eq(true)

      expect(page).to have_content("Claim decision")

      choose "Approve"
      fill_in "Decision notes", with: "All checks passed!"
      click_on "Confirm decision"

      expect(page).to have_content("Claim has been approved successfully")
      expect(claim.reload.latest_decision).to be_approved
      expect(claim.reload.latest_decision.created_by).to eq(@signed_in_user)
    end
  end
end
