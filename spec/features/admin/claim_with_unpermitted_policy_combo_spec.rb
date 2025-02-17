require "rails_helper"

RSpec.describe "Claim with unpermitted policy combo" do
  context "when one of the claims has been approved" do
    it "doesn't allow the admin to approve the other claim" do
      create(
        :claim,
        :approved,
        :current_academic_year,
        policy: Policies::InternationalRelocationPayments,
        email_address: "duplicate@example.com"
      )

      duplicate_claim = create(
        :claim,
        :submitted,
        :current_academic_year,
        policy: Policies::FurtherEducationPayments,
        email_address: "duplicate@example.com"
      )

      sign_in_as_service_operator

      visit new_admin_claim_decision_path(duplicate_claim)

      approve_option = find("input[type=radio][value=approved]")

      expect(approve_option).to be_disabled
    end
  end

  context "when neither of the claims have been approved" do
    it "allows the admin to approve one of the claims" do
      irp_claim = create(
        :claim,
        :submitted,
        :current_academic_year,
        policy: Policies::InternationalRelocationPayments,
        email_address: "duplicate@example.com"
      )

      fe_claim = create(
        :claim,
        :submitted,
        :current_academic_year,
        policy: Policies::FurtherEducationPayments,
        email_address: "duplicate@example.com"
      )

      sign_in_as_service_operator

      visit new_admin_claim_decision_path(irp_claim)

      approve_option = find("input[type=radio][value=approved]")

      expect(approve_option).not_to be_disabled

      visit new_admin_claim_decision_path(fe_claim)

      approve_option = find("input[type=radio][value=approved]")

      expect(approve_option).not_to be_disabled

      choose "Approve"

      fill_in "Decision notes", with: "LGTM"

      click_on "Confirm decision"

      visit new_admin_claim_decision_path(irp_claim)

      approve_option = find("input[type=radio][value=approved]")

      expect(approve_option).to be_disabled
    end
  end
end
