require "rails_helper"

RSpec.describe "Admin claim checks", type: :request do
  context "when signed in as a service operator" do
    let(:user) { create(:dfe_signin_user) }

    before do
      sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
      @dataset_post_stub = stub_geckoboard_dataset_update
    end

    describe "claim_checks#create" do
      let(:claim) { create(:claim, :submitted) }

      it "can approve a claim" do
        post admin_claim_checks_path(claim_id: claim.id, check: {result: "approved"})

        follow_redirect!

        expect(response.body).to include("Claim has been approved successfully")

        expect(claim.check.checked_by).to eq(user)
        expect(claim.check.result).to eq("approved")
      end

      it "can reject a claim" do
        post admin_claim_checks_path(claim_id: claim.id, check: {result: "rejected"})

        follow_redirect!

        expect(response.body).to include("Claim has been rejected successfully")

        expect(claim.check.checked_by).to eq(user)
        expect(claim.check.result).to eq("rejected")
      end

      it "updates the claim dataset on Geckoboard" do
        perform_enqueued_jobs { post admin_claim_checks_path(claim_id: claim.id, check: {result: "approved"}) }

        expect(@dataset_post_stub.with { |request|
          request_body_matches_geckoboard_data_for_claims?(request, [claim.reload])
        }).to have_been_requested
      end

      context "when no result is selected" do
        it "shows an error and doesn't save the check" do
          post admin_claim_checks_path(claim_id: claim.id, check: {notes: "Something"})

          expect(response.body).to include("Make a decision to approve or reject the claim")
          expect(claim.reload.check).to be_nil
        end
      end

      context "when claim is already checked" do
        let(:claim) { create(:claim, :approved) }

        it "shows an error" do
          post admin_claim_checks_path(claim_id: claim.id, check: {result: "approved"})

          follow_redirect!

          expect(response.body).to include("Claim already checked")
        end
      end

      context "when the claim is missing a payroll gender" do
        let(:claim) { create(:claim, :submitted, payroll_gender: :dont_know) }
        before do
          post admin_claim_checks_path(claim_id: claim.id, check: {result: result})
          follow_redirect!
        end

        context "and the user attempts to approve" do
          let(:result) { "approved" }
          it "shows an error" do
            expect(response.body).to include("Claim cannot be approved")
          end
        end

        context "and the user attempts to reject" do
          let(:result) { "rejected" }
          it "doesn’t show an error and rejects successfully" do
            expect(response.body).not_to include("Claim cannot be approved")
            expect(response.body).to include("Claim has been rejected successfully")
          end
        end
      end

      context "when the claimant has another approved claim in the same payroll window, with inconsistent personal details" do
        let(:personal_details) do
          {
            national_insurance_number: generate(:national_insurance_number),
            teacher_reference_number: generate(:teacher_reference_number),
            date_of_birth: 30.years.ago.to_date,
            student_loan_plan: StudentLoan::PLAN_1,
            email_address: "email@example.com",
            bank_sort_code: "112233",
            bank_account_number: "95928482",
            building_society_roll_number: nil,
          }
        end
        let(:claim) { create(:claim, :submitted, personal_details.merge(bank_sort_code: "582939", bank_account_number: "74727752")) }
        let!(:approved_claim) { create(:claim, :approved, personal_details.merge(bank_sort_code: "112233", bank_account_number: "29482823")) }
        before do
          post admin_claim_checks_path(claim_id: claim.id, check: {result: result})
          follow_redirect!
        end

        context "and the user attempts to approve" do
          let(:result) { "approved" }
          it "shows an error" do
            expect(response.body).to include("Claim cannot be approved because there are inconsistent claims")
          end
        end

        context "and the user attempts to reject" do
          let(:result) { "rejected" }
          it "doesn’t show an error and rejects successfully" do
            expect(response.body).not_to include("Claim cannot be approved")
            expect(response.body).to include("Claim has been rejected successfully")
          end
        end
      end
    end
  end

  context "when signed in as a payroll operator or a support agent" do
    describe "claim_checks#create" do
      let(:claim) { create(:claim, :submitted) }

      [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
        it "does not allow a claim to be approved" do
          sign_in_to_admin_with_role(role)
          post admin_claim_checks_path(claim_id: claim.id, result: "approved")

          expect(response.code).to eq("401")
        end
      end
    end
  end
end
