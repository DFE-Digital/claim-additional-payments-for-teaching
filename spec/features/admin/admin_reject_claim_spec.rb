require "rails_helper"

RSpec.feature "Admin rejects a claim" do
  let!(:claim) { create(:claim, :submitted) }

  before do
    disable_claim_qa_flagging
    @signed_in_user = sign_in_as_service_operator
  end

  scenario "Reject a claim with a selected reason" do
    visit admin_claim_tasks_path(claim)
    click_on "Approve or reject this claim"
    choose "Reject"
    check "Ineligible subject"
    click_button "Confirm decision"

    expect(page).to have_content("Claim has been rejected successfully")

    visit admin_claim_path(claim)

    expect(page).to have_content("Result Rejected")
    expect(page).to have_content("Reasons Ineligible subject")
  end

  scenario "Reject a claim with more than one selected reason" do
    visit admin_claim_tasks_path(claim)
    click_on "Approve or reject this claim"
    choose "Reject"
    check "Ineligible subject"
    check "Duplicate"
    click_button "Confirm decision"

    expect(page).to have_content("Claim has been rejected successfully")

    visit admin_claim_path(claim)

    expect(page).to have_content("Result Rejected")
    expect(page).to have_content("Reasons Ineligible subject, Duplicate")
  end

  scenario "Rejecting an ECP claim with Induction - ECP only" do
    claim = create(:claim, :submitted, policy: Policies::EarlyCareerPayments)

    visit admin_claim_tasks_path(claim)
    click_on "Approve or reject this claim"
    choose "Reject"
    check "Induction - ECP only"
    click_button "Confirm decision"

    expect(page).to have_content("Claim has been rejected successfully")

    visit admin_claim_path(claim)

    expect(page).to have_content("Result Rejected")
    expect(page).to have_content("Reasons Induction - ECP only")
  end

  scenario "Rejecting a claim with Other with a note" do
    visit admin_claim_tasks_path(claim)
    click_on "Approve or reject this claim"
    choose "Reject"
    check "Ineligible subject"
    check "Other"
    fill_in "Decision notes", with: "Blah blah"
    click_button "Confirm decision"

    expect(page).to have_content("Claim has been rejected successfully")

    visit admin_claim_path(claim)

    expect(page).to have_content("Result Rejected")
    expect(page).to have_content("Reasons Ineligible subject, Other")
    expect(page).to have_content("Blah blah")
  end

  scenario "Rejecting a claim with no reason checked" do
    visit admin_claim_tasks_path(claim)
    click_on "Approve or reject this claim"
    choose "Reject"
    click_button "Confirm decision"

    expect(page).to have_content("At least one reason is required")
  end

  scenario "Rejecting a claim with Other selected requires a note" do
    visit admin_claim_tasks_path(claim)
    click_on "Approve or reject this claim"
    choose "Reject"
    check "Other"
    click_button "Confirm decision"

    expect(page).to have_content("You must enter a reason for rejecting this claim in the decision note")
  end

  scenario "Rejecting a claim with Other selected requires a note" do
    visit admin_claim_tasks_path(claim)
    click_on "Approve or reject this claim"
    choose "Reject"
    check "Duplicate"
    choose "Approve"
    click_button "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(claim.reload.decisions.last.rejected_reasons.values.uniq).to eq([nil])

    visit admin_claim_path(claim)

    expect(page).not_to have_content("Reasons")
  end

  context "early years claim" do
    let!(:claim) do
      create(
        :claim,
        :submitted,
        policy: Policies::EarlyYearsPayments
      )
    end

    scenario "rejecting sends email to claimant + provider" do
      visit admin_claim_tasks_path(claim)
      click_on "Approve or reject this claim"
      choose "Reject"
      check "Claim cancelled by employer"

      expect {
        click_button "Confirm decision"
      }.to change { enqueued_jobs.count { |job| job[:job] == ActionMailer::MailDeliveryJob } }.by(2)

      expect(page).to have_content("Claim has been rejected successfully")
    end
  end
end
