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

  context "when an claim already approved for the academic year for that policy exists" do
    context "when another claim is already approved and payrolled for this policy with same email address" do
      let(:claim_attributes) do
        {
          policy: Policies::StudentLoans,
          email_address: "same-email@example.com"
        }
      end

      let(:payroll_run) { create(:payroll_run) }

      let(:approved_claim) do
        claim = create(:claim, :approved, **claim_attributes)
        create(:payment, claims: [claim], payroll_run:)

        claim
      end

      let(:submitted_claim) { create(:claim, :submitted, **claim_attributes) }

      before do
        approved_claim
        submitted_claim
      end

      it "shows an error with claim reference and submitted claim cannot be approved" do
        sign_in_as_service_operator

        visit new_admin_claim_decision_path(submitted_claim)

        choose "Approve"
        click_on "Confirm decision"

        expect(page.body)
          .to have_content(/Duplicate claim has already been approved with reference #{approved_claim.reference}/)
      end
    end

    context "when multiple claims are already approved for the academic year" do
      let(:claim_attributes) do
        {
          policy: Policies::StudentLoans,
          email_address: "same-email@example.com"
        }
      end

      let(:payroll_run) { create(:payroll_run) }

      let(:approved_claim_1) do
        claim = create(:claim, :approved, **claim_attributes)
        create(:payment, claims: [claim], payroll_run:)

        claim
      end

      let(:approved_claim_2) do
        claim = create(:claim, :approved, **claim_attributes)
        create(:payment, claims: [claim], payroll_run:)

        claim
      end

      let(:submitted_claim) { create(:claim, :submitted, **claim_attributes) }

      before do
        approved_claim_1
        approved_claim_2
        submitted_claim
      end

      it "shows an error with multiple claim references in plural form" do
        sign_in_as_service_operator

        visit new_admin_claim_decision_path(submitted_claim)

        choose "Approve"
        click_on "Confirm decision"

        expect(page.body)
          .to have_content(/Duplicate claims have already been approved with references #{approved_claim_1.reference}, #{approved_claim_2.reference}/)
      end
    end
  end
end
