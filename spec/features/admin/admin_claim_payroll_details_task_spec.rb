require "rails_helper"

RSpec.feature "Admin checking a claim's payroll details" do
  before do
    create(:journey_configuration, :student_loans)
    disable_claim_qa_flagging
    @signed_in_user = sign_in_as_service_operator
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
      expect(page).to have_content I18n.t("admin.tasks.payroll_details.title")

      expect(page.find(".app-task-list__item.payroll_details")).to have_text("Incomplete")

      click_on I18n.t("admin.tasks.payroll_details.title")

      expect(page).to have_content I18n.t(
        "admin.tasks.payroll_details.question",
        bank_or_building_society: I18n.t("admin.#{claim.bank_or_building_society}"),
        claimant_name: claim.full_name
      )

      # Can't match entire payload due to whitespace mismatch
      claim.hmrc_bank_validation_responses.each do |response|
        expect(page.find(".hmrc_responses")).to have_text(response["code"])
        expect(page.find(".hmrc_responses")).to have_text(response["body"])
      end

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

  context "when the claim has been scrubbed" do
    let!(:claim) do
      create(
        :claim,
        :submitted,
        :personal_data_removed
      )
    end

    scenario "does not show the hmrc response" do
      visit admin_claim_task_path(claim, "payroll_details")

      expect(page).to have_content(
        "This claim has had it's personal data removed."
      )
    end
  end
end
