require "rails_helper"

RSpec.feature "Admin stats" do
  let(:submitted_claims) { create_list(:claim, 6, :submitted) }
  let!(:school_workforce_census_task_any_match) { create(:task, claim: submitted_claims.first, name: "census_subjects_taught", claim_verifier_match: :any) }
  let!(:school_workforce_census_task_no_match) { create(:task, claim: submitted_claims.second, name: "census_subjects_taught", claim_verifier_match: :none) }
  let!(:school_workforce_census_task_no_data) { create(:task, claim: submitted_claims.third, name: "census_subjects_taught") }
  before do
    @approved_claims = create_list(:claim, 4, :approved, submitted_at: 10.weeks.ago)
    @unfinished_claims = create_list(:claim, 1, :submittable)
    @claims_approaching_deadline = create_list(:claim, 2, :submitted, submitted_at: (Claim::DECISION_DEADLINE - 1.week).ago)
    @claims_passed_deadline = create_list(:claim, 1, :submitted, submitted_at: (Claim::DECISION_DEADLINE + 1.week).ago)
    sign_in_as_service_operator
    visit admin_root_path
  end

  scenario "Service operator is shown total numbers of claims in various states" do
    expect(page).to have_text("Total claims received\n#{Claim.submitted.count}")
    expect(page).to have_text("Claims awaiting a decision\n#{Claim.awaiting_decision.count}")
    expect(page).to have_text("Claims approaching deadline\n#{@claims_approaching_deadline.count}")
    expect(page).to have_text("Claims passed deadline\n#{@claims_passed_deadline.count}")
  end

  scenario "Service operator is shown \% of claims and status for the School Workforce Census check" do
    expect(page).to have_text("School Workforce Census Stats")
    expect(page).to have_text("Not checked\n#{((Claim.submitted.count.to_f - Task.census_subjects_taught.count) / Claim.submitted.count.to_f * 100 / 1).round(1)}")
    expect(page).to have_text("Any Match\n7.7%")
    expect(page).to have_text("No Match\n7.7%")
    expect(page).to have_text("No data\n7.7%")
    expect(page).to have_text("Passed\n23.1%")
    expect(page).to have_text("Failed\n0.0%")
  end
end
