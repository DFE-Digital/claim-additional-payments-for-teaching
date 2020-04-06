require "rails_helper"

RSpec.feature "Admin can view completed claims" do
  before { @signed_in_user = sign_in_as_service_operator }

  scenario "Viewing a claim that has a decision made " do
    claim_with_decision = create(:claim, :approved)

    visit admin_claim_tasks_path(claim_with_decision)

    within("span#claim-heading") do
      expect(page).to have_content("Approved")
    end
  end

  scenario "Viewing a claim that does not have decision made" do
    claim_without_decision = create(:claim, :submitted)

    visit admin_claim_tasks_path(claim_without_decision)

    within("span#claim-heading") do
      expect(page).to have_content(claim_without_decision.reference)
    end
  end
end
