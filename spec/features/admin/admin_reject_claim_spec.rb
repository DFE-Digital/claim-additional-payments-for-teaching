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
    context "claimant has not completed their half" do
      let!(:claim) do
        create(
          :claim,
          :submitted,
          policy: Policies::EarlyYearsPayments,
          email_address: nil
        )
      end

      scenario "rejecting sends email to provider only when claimant yet to complete" do
        visit admin_claim_tasks_path(claim)
        click_on "Approve or reject this claim"
        choose "Reject"
        check "Claim cancelled by employer"

        expect {
          click_button "Confirm decision"
        }.to change { enqueued_jobs.count { |job| job[:job] == ActionMailer::MailDeliveryJob } }.by(1)

        expect(page).to have_content("Claim has been rejected successfully")
      end
    end

    context "claimant has completed their half" do
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

  context "QA required for a rejected claim" do
    let(:policy) { Policies::FurtherEducationPayments }

    let(:claim) { create(:claim, :submitted, policy: policy) }

    around do |example|
      perform_enqueued_jobs { example.run }
    end

    before do
      stub_const("Policies::#{policy}::REJECTED_MIN_QA_THRESHOLD", 100)
    end

    context "when rejecting during QA" do
      it "rejects the claim" do
        visit admin_claim_tasks_path(claim)

        click_on "Approve or reject this claim"

        choose "Reject"

        check "No teaching responsibilities"

        click_button "Confirm decision"

        expect(claim.email_address).not_to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:CLAIM_REJECTED_NOTIFY_TEMPLATE_ID]
        )

        expect(page).to have_content(
          "This claim has been marked for a quality assurance review"
        )

        visit admin_claim_tasks_path(claim)

        click_on "Approve or reject quality assurance of this claim"

        choose "Reject"

        check "Identity check failed"

        fill_in "Decision notes", with: "QA failed"

        click_button "Confirm decision"

        expect(page).to have_content("Claim has been rejected successfully")

        expect(claim.email_address).to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:CLAIM_REJECTED_NOTIFY_TEMPLATE_ID]
        )

        visit admin_claim_decisions_path(claim)

        expect(page).to have_content("Result Rejected").twice
      end
    end

    context "when approving during QA" do
      it "approves the claim" do
        visit admin_claim_tasks_path(claim)

        click_on "Approve or reject this claim"

        choose "Reject"

        check "No teaching responsibilities"

        click_button "Confirm decision"

        expect(claim.email_address).not_to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:CLAIM_REJECTED_NOTIFY_TEMPLATE_ID]
        )

        expect(page).to have_content(
          "This claim has been marked for a quality assurance review"
        )

        visit admin_claim_tasks_path(claim)

        click_on "Approve or reject quality assurance of this claim"

        choose "Approve"

        fill_in "Decision notes", with: "QA passed"

        click_button "Confirm decision"

        expect(page).to have_content("Claim has been approved successfully")

        expect(claim.email_address).to have_received_email(
          ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:CLAIM_APPROVED_NOTIFY_TEMPLATE_ID]
        )

        visit admin_claim_decisions_path(claim)

        expect(page).to have_content("Result Rejected").once

        expect(page).to have_content("Result Approved").once
      end
    end
  end
end
