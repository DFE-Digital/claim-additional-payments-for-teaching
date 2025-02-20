require "rails_helper"

RSpec.describe "Approvals" do
  before do
    stub_const("Policies::EarlyYearsPayments::APPROVED_MIN_QA_THRESHOLD", 0)
  end

  context "when the claim is auto-approved" do
    context "when the claim is for an EarlyYearsPayment" do
      it "emails the provider and practitioner" do
        provider = create(
          :eligible_ey_provider,
          primary_key_contact_email_address: "provider@example.com"
        )

        claim = create(
          :claim,
          :approveable,
          :current_academic_year,
          policy: Policies::EarlyYearsPayments,
          email_address: "practitioner@example.com",
          first_name: "practitioner_first_name",
          surname: "practitioner_last_name",
          provider_contact_name: "provider_contact_name",
          eligibility_attributes: {
            nursery_urn: provider.urn
          }
        )

        perform_enqueued_jobs do
          AutoApproveClaimsJob.perform_now
        end

        expect("practitioner@example.com").to have_received_email(
          "13b60fab-8306-4cb4-84e1-8a0ff905aba6",
          ref_number: claim.reference,
          first_name: "practitioner_first_name"
        )

        expect("provider@example.com").to have_received_email(
          "aa714fac-3fd7-4d3c-a510-2445c16be446",
          ref_number: claim.reference,
          first_name: "provider_contact_name",
          practitioner_first_name: "practitioner_first_name",
          practitioner_last_name: "practitioner_last_name"
        )
      end
    end
  end

  context "when the claim is manually approved" do
    context "when the claim is for an EarlyYearsPayment" do
      it "emails the provider and practitioner" do
        provider = create(
          :eligible_ey_provider,
          primary_key_contact_email_address: "provider@example.com"
        )

        claim = create(
          :claim,
          :approveable,
          :current_academic_year,
          policy: Policies::EarlyYearsPayments,
          email_address: "practitioner@example.com",
          first_name: "practitioner_first_name",
          surname: "practitioner_last_name",
          provider_contact_name: "provider_contact_name",
          eligibility_attributes: {
            nursery_urn: provider.urn
          }
        )

        sign_in_as_service_operator

        visit new_admin_claim_decision_path(claim)

        choose "Approve"

        fill_in "Decision notes", with: "LGTM"

        perform_enqueued_jobs do
          click_on "Confirm decision"
        end

        expect("practitioner@example.com").to have_received_email(
          "13b60fab-8306-4cb4-84e1-8a0ff905aba6",
          ref_number: claim.reference,
          first_name: "practitioner_first_name"
        )

        expect("provider@example.com").to have_received_email(
          "aa714fac-3fd7-4d3c-a510-2445c16be446",
          ref_number: claim.reference,
          first_name: "provider_contact_name",
          practitioner_first_name: "practitioner_first_name",
          practitioner_last_name: "practitioner_last_name"
        )
      end
    end
  end
end
