require "rails_helper"

RSpec.feature "Admin stats" do
  let(:submitted_claims) { create_list(:claim, 6, :submitted) }
  let!(:school_workforce_census_task_any_match) { create(:task, claim: submitted_claims.first, name: "census_subjects_taught", claim_verifier_match: :any) }
  let!(:school_workforce_census_task_no_match) { create(:task, claim: submitted_claims.second, name: "census_subjects_taught", claim_verifier_match: :none) }
  let!(:school_workforce_census_task_no_data) { create(:task, claim: submitted_claims.third, name: "census_subjects_taught") }
  before do
    @approved_claims = create_list(:claim, 3, :approved, submitted_at: 10.weeks.ago)
    @rejected_claims = create_list(:claim, 1, :rejected)
    @claims_approaching_deadline = create_list(:claim, 2, :submitted, submitted_at: (Claim::DECISION_DEADLINE - 1.week).ago)
    @claims_passed_deadline = create_list(:claim, 1, :submitted, submitted_at: (Claim::DECISION_DEADLINE + 1.week).ago)

    allow(AcademicYear).to receive(:current).and_return(AcademicYear.new("2019/2020"))

    sign_in_as_service_operator
    visit admin_root_path
  end

  scenario "Service operator is shown total numbers of claims in various states" do
    # Left column
    expect(page).to have_text("Claims received (2019/2020)\n13")
    expect(page).to have_text("Claims approved (2019/2020)\n3")
    expect(page).to have_text("Claims rejected (2019/2020)\n1")

    # Right column
    expect(page).to have_text("Total claims received\n13")
    expect(page).to have_text("Claims approaching deadline\n2")
    expect(page).to have_text("Claims passed deadline\n1")
  end

  scenario "Service operator is shown % of claims and status for the School Workforce Census check" do
    expect(page).to have_text("School Workforce Census Statistics")
    expect(page).to have_text("Any matches\n7.7%")
    expect(page).to have_text("No data\n7.7%")
  end
end

RSpec.feature "School Workforce Census contains rows" do
  scenario "Shows a warning" do
    sign_in_as_service_operator
    visit admin_root_path
    expect(page).to have_text("There is currently no School Workforce Census data present")
  end
end

RSpec.feature "School Workforce Census contains NO rows" do
  before do
    create(:school_workforce_census, :early_career_payments_matched)
  end

  scenario "Does not show a warning" do
    sign_in_as_service_operator
    visit admin_root_path
    expect(page).not_to have_text("There is currently no School Workforce Census data present")
  end
end
