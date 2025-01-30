require "rails_helper"

RSpec.describe "Admin Topup Claim" do
  let(:claim) do
    create(
      :claim,
      :approved,
      policy: Policies::EarlyCareerPayments,
      eligibility_attributes: {
        award_amount: 1_000.00
      }
    )
  end

  before { sign_in_as_service_operator }

  context "when the claim hasn't been payrolled" do
    it "doesn't let an admin add a topup" do
      visit admin_claim_tasks_path(claim)

      expect(page).not_to have_content("Top up claim")
    end
  end

  context "when the claim has been payrolled" do
    before do
      create(
        :payment,
        claims: [claim],
        payroll_run: create(:payroll_run)
      )
    end

    it "lets an admin add a topup" do
      visit admin_claim_tasks_path(claim)

      click_on "Top up claim"

      fill_in "Top up amount", with: "100.55"

      click_on "Top up"

      expect(page).to have_content("Confirm £100.55 is the correct amount")

      click_on "Confirm"

      expect(page).to have_content("Claim top up payment created")

      visit admin_claim_notes_path(claim)

      expect(page).to have_content("Claim amount £1,100.55")

      expect(page).to have_text(
        "£100.55 top up added by Aaron Admin",
        normalize_ws: true
      )
    end

    it "lets an admin remove a topup" do
      create(:topup, claim: claim, award_amount: 100.55)

      visit admin_claim_payments_path(claim)

      click_on "Remove"

      expect(page).to have_content(
        "Are you sure you want to remove the top up of £100.55"
      )

      click_on "Remove top up"

      expect(page).to have_content("Claim amount £1,000.00")

      visit admin_claim_notes_path(claim)

      expect(page).to have_text(
        "£100.55 top up removed by Aaron Admin",
        normalize_ws: true
      )
    end
  end
end
