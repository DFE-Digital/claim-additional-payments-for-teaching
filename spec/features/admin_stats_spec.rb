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
    expect(page).to have_text("School Workforce Census Statistics")
    expect(page).to have_text("Any matches\n7.7%")
    expect(page).to have_text("No data\n7.7%")
  end
end

RSpec.feature "School workforce census contains rows" do
  scenario "Shows a warning" do
    sign_in_as_service_operator
    visit admin_root_path
    expect(page).to have_text("There is currently no school workforce data present")
  end
end

RSpec.feature "School workforce census contains NO rows" do
  before do
    create(:school_workforce_census, :early_career_payments_matched)
  end

  scenario "Does not show a warning" do
    sign_in_as_service_operator
    visit admin_root_path
    expect(page).not_to have_text("There is currently no school workforce data present")
  end
end
