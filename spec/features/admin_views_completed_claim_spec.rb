require "rails_helper"

RSpec.feature "Admin can view completed claims" do
  before do
    create(:policy_configuration, :student_loans)
    @signed_in_user = sign_in_as_service_operator
  end

  scenario "Viewing a claim that has a decision made" do
    claim_with_decision = create(:claim, :approved)

    visit admin_claim_tasks_path(claim_with_decision)

    within("span#claim-heading") do
      expect(page).to have_content("Approved")
    end
    expect(page).to have_content("Claim amount £1,000.00")
  end

  scenario "Viewing a claim that does not have decision made" do
    claim_without_decision = create(:claim, :submitted)

    visit admin_claim_tasks_path(claim_without_decision)

    within("span#claim-heading") do
      expect(page).to have_content(claim_without_decision.reference)
    end
  end

  scenario "Viewing an approved claim which has a payment" do
    payroll_run = create(:payroll_run, claims_counts: {StudentLoans => 1})
    claim_with_payment = payroll_run.claims.first

    visit admin_claim_tasks_path(claim_with_payment)

    expect(page).to have_content("Status Payrolled")
  end

  scenario "Viewing a payroll status for an approved claim which hasn't had a payment" do
    claim_with_decision = create(:claim, :approved)

    visit admin_claim_tasks_path(claim_with_decision)

    expect(page).to have_content("Status Approved awaiting payroll")
  end
end
