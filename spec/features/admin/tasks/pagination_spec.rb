require "rails_helper"

RSpec.feature "Admin paginates thru tasks" do
  before do
    sign_in_as_service_operator
  end

  context "when new claim" do
    let!(:claim) { create(:claim, :submitted) }

    scenario "can paginate thru to decision" do
      visit admin_claims_path
      click_link claim.reference
      click_link "Check student loan amount"
      click_link "Next:Decision"

      expect(page).to have_link "Previous:Student loan amount"
      expect(page).not_to have_content "Next"
    end
  end

  context "when claim approved and needs QA" do
    let!(:claim) { create(:claim, :submitted, :flagged_for_qa) }

    scenario "can pagainate thru to QA decision" do
      visit admin_claims_path
      click_link claim.reference
      click_link "Check student loan amount"
      click_link "Next:Decision"

      expect(page).to have_link "Previous:Student loan amount"
      click_link "Next:QA decision"

      expect(page).to have_link "Previous:Decision"
      expect(page).not_to have_content "Next"
    end
  end

  context "when QA-ed" do
    let!(:decision) { create(:decision, :approved, claim:) }
    let!(:claim) { create(:claim, :submitted, :qa_completed) }

    scenario "can pagainate thru to QA decision" do
      visit admin_claim_tasks_path(claim.id)
      click_link "Check student loan amount"
      click_link "Next:Decision"

      expect(page).to have_link "Previous:Student loan amount"
      click_link "Next:QA decision"

      expect(page).to have_link "Previous:Decision"
      expect(page).not_to have_content "Next"
    end
  end
end
