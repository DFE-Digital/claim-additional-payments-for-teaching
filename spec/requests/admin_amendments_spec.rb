require "rails_helper"

RSpec.describe "Admin claim amendments" do
  let(:claim) { create(:claim, :submitted, teacher_reference_number: "1234567", bank_sort_code: "010203", date_of_birth: 25.years.ago.to_date) }

  context "when signed in as a service operator" do
    let(:service_operator) { create(:dfe_signin_user) }
    before do
      sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, service_operator.dfe_sign_in_id)
    end

    describe "admin_amendments#create" do
      it "creates an amendment and updates the claim" do
        old_date_of_birth = claim.date_of_birth
        new_date_of_birth = 30.years.ago.to_date
        expect {
          post admin_claim_amendments_url(claim, amendment: {claim: {teacher_reference_number: "7654321", "bank_sort_code": "111213", "date_of_birth(3i)": new_date_of_birth.day, "date_of_birth(2i)": new_date_of_birth.month, "date_of_birth(1i)": new_date_of_birth.year},
                                                             notes: "Claimant made a typo"})
        }.to change { claim.reload.amendments.size }.by(1)

        expect(response).to redirect_to(admin_claim_tasks_url(claim))

        amendment = claim.amendments.last
        expect(amendment.claim_changes).to eq({
          "teacher_reference_number" => ["1234567", "7654321"],
          "bank_sort_code" => ["010203", "111213"],
          "date_of_birth" => [old_date_of_birth, new_date_of_birth]
        })
        expect(amendment.claim_changes).to be_a(Hash)
        expect(amendment.notes).to eq("Claimant made a typo")
        expect(amendment.created_by).to eq(service_operator)

        expect(claim.teacher_reference_number).to eq("7654321")
        expect(claim.bank_sort_code).to eq("111213")
        expect(claim.date_of_birth).to eq(new_date_of_birth)
      end

      it "saves the normalised value in the amendment when updating bank sort code" do
        post admin_claim_amendments_url(claim, amendment: {claim: {bank_sort_code: "11 12 13"}, notes: "Claimant made a typo"})

        expect(response).to redirect_to(admin_claim_tasks_url(claim))

        expect(claim.reload.amendments.last.claim_changes).to eq({"bank_sort_code" => ["010203", "111213"]})
        expect(claim.bank_sort_code).to eq("111213")
      end

      it "doesn't record a change when changing a value from nil to an empty string" do
        claim.update!(building_society_roll_number: nil)

        post admin_claim_amendments_url(claim, amendment: {claim: {bank_sort_code: "111213", building_society_roll_number: ""},
                                                           notes: "Claimant made a typo"})

        expect(response).to redirect_to(admin_claim_tasks_url(claim))

        expect(claim.reload.amendments.last.claim_changes).to eq({"bank_sort_code" => ["010203", "111213"]})
      end

      it "displays a validation error and does not update the claim or create an amendment when invalid values are entered" do
        expect {
          post admin_claim_amendments_url(claim, amendment: {claim: {teacher_reference_number: "654321", bank_account_number: ""},
                                                             notes: "Claimant made a typo"})
        }.not_to change { [claim.reload.teacher_reference_number, claim.amendments.size] }

        expect(response).to have_http_status(:ok)

        expect(response.body).to include("Teacher reference number must contain seven digits")
        expect(response.body).to include("Enter an account number")
      end

      it "displays an error message and does not create an amendment when none of the claim’s values are changed" do
        expect {
          post admin_claim_amendments_url(claim, amendment: {claim: {teacher_reference_number: claim.teacher_reference_number},
                                                             notes: "Claimant made a typo"})
        }.not_to change { [claim.reload.teacher_reference_number, claim.amendments.size] }

        expect(response).to have_http_status(:ok)

        expect(response.body).to include("To amend the claim you must change at least one value")
      end

      it "raises an error and does not create an amendment or update the claim when attempting to modify an attribute that isn’t in the allowed list" do
        original_counts = [claim.national_insurance_number, claim.amendments.size]

        expect {
          post admin_claim_amendments_url(claim, amendment: {claim: {national_insurance_number: generate(:national_insurance_number)},
                                                             notes: "Claimant made a typo"})
        }.to raise_error(
          ActionController::UnpermittedParameters
        )

        expect([claim.national_insurance_number, claim.amendments.size]).to eq(original_counts)
      end

      context "when the claim is not amendable" do
        let(:claim) { create(:claim, :rejected) }

        it "shows an error" do
          post admin_claim_amendments_url(claim, amendment: {claim: {teacher_reference_number: claim.teacher_reference_number},
                                                             notes: "Claimant made a typo"})
          expect(response.body).to include("This claim cannot be amended.")
        end
      end
    end
  end

  context "when signed in as a payroll operator or a support agent" do
    [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
      before do
        sign_in_to_admin_with_role(role)
      end

      describe "admin_amendments#new" do
        it "returns a unauthorized response" do
          get new_admin_claim_amendment_url(claim)

          expect(response).to have_http_status(:unauthorized)
        end
      end

      describe "admin_amendments#create" do
        it "returns a unauthorized response and does not create an amendment or change the claim" do
          expect {
            post admin_claim_amendments_url(claim, amendment: {claim: {teacher_reference_number: "7654321"}})
          }.not_to change { [claim.reload.teacher_reference_number, claim.amendments.size] }

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
