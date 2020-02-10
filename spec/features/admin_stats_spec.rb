require "rails_helper"

RSpec.feature "Admin stats" do
  before do
    @submitted_claims = create_list(:claim, 6, :submitted)
    @approved_claims = create_list(:claim, 4, :approved, submitted_at: 10.weeks.ago)
    @unfinished_claims = create_list(:claim, 1, :submittable)
    @claims_approaching_deadline = create_list(:claim, 2, :submitted, submitted_at: (Claim::DECISION_DEADLINE - 1.week).ago)
    @claims_passed_deadline = create_list(:claim, 1, :submitted, submitted_at: (Claim::DECISION_DEADLINE + 1.week).ago)
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
    visit admin_root_path
  end

  scenario "Service operator is shown total numbers of claims in various states" do
    expect(page).to have_text("Total claims received\n#{Claim.submitted.count}")
    expect(page).to have_text("Claims awaiting a decision\n#{Claim.awaiting_decision.count}")
    expect(page).to have_text("Claims approaching deadline\n#{@claims_approaching_deadline.count}")
    expect(page).to have_text("Claims passed deadline\n#{@claims_passed_deadline.count}")
  end
end
