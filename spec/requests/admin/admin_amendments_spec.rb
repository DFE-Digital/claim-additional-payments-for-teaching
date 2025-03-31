require "rails_helper"

RSpec.describe "Admin claim amendments" do
  let(:claim) do
    create(
      :claim,
      :submitted,
      eligibility_attributes: {
        teacher_reference_number: "1234567"
      },
      bank_sort_code: "010203",
      date_of_birth: 25.years.ago.to_date
    )
  end

  context "when signed in as a service operator" do
    before { @signed_in_user = sign_in_as_service_operator }

    describe "admin/amendments#index" do
      let(:claim) { create(:claim, :submitted, eligibility_attributes: {teacher_reference_number: "1234567"}) }
      let!(:amendment) { create(:amendment, claim: claim, notes: "Made a change", claim_changes: {"teacher_reference_number" => ["7654321", "1234567"]}) }

      it "list the amendments on a claim" do
        get admin_claim_amendments_path(claim)

        expect(response.body).to include("changed from 7654321 to 1234567")
        expect(response.body).to include("Made a change")
      end
    end

    describe "admin_amendments#create" do
      it "creates an amendment and updates the claim" do
        old_date_of_birth = claim.date_of_birth
        new_date_of_birth = 30.years.ago.to_date

        request_params = {
          amendment: {
            teacher_reference_number: "7654321",
            national_insurance_number: claim.national_insurance_number,
            bank_sort_code: "111213",
            bank_account_number: claim.bank_account_number,
            student_loan_plan: claim.student_loan_plan,
            student_loan_repayment_amount: claim.eligibility.student_loan_repayment_amount,
            "date_of_birth(3i)": new_date_of_birth.day,
            "date_of_birth(2i)": new_date_of_birth.month,
            "date_of_birth(1i)": new_date_of_birth.year,
            address_line_1: claim.address_line_1,
            address_line_2: claim.address_line_2,
            address_line_3: claim.address_line_3,
            address_line_4: claim.address_line_4,
            postcode: claim.postcode,
            notes: "Claimant made a typo"
          }
        }

        expect {
          post admin_claim_amendments_url(claim, request_params)
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
        expect(amendment.created_by).to eq(@signed_in_user)

        expect(claim.eligibility.teacher_reference_number).to eq("7654321")
        expect(claim.bank_sort_code).to eq("111213")
        expect(claim.date_of_birth).to eq(new_date_of_birth)
      end

      it "saves the normalised value in the amendment when updating bank sort code" do
        request_params = {
          amendment: {
            teacher_reference_number: claim.eligibility.teacher_reference_number,
            national_insurance_number: claim.national_insurance_number,
            bank_sort_code: "11 12 13",
            bank_account_number: claim.bank_account_number,
            student_loan_plan: claim.student_loan_plan,
            student_loan_repayment_amount: claim.eligibility.student_loan_repayment_amount,
            "date_of_birth(3i)": claim.date_of_birth.day,
            "date_of_birth(2i)": claim.date_of_birth.month,
            "date_of_birth(1i)": claim.date_of_birth.year,
            address_line_1: claim.address_line_1,
            address_line_2: claim.address_line_2,
            address_line_3: claim.address_line_3,
            address_line_4: claim.address_line_4,
            postcode: claim.postcode,
            notes: "Claimant made a typo"
          }
        }

        post admin_claim_amendments_url(claim, request_params)

        expect(response).to redirect_to(admin_claim_tasks_url(claim))

        expect(claim.reload.amendments.last.claim_changes).to eq({"bank_sort_code" => ["010203", "111213"]})
        expect(claim.bank_sort_code).to eq("111213")
      end

      it "doesn't record a change when changing a value from nil to an empty string" do
        claim.update!(address_line_4: nil)

        request_params = {
          amendment: {
            teacher_reference_number: claim.eligibility.teacher_reference_number,
            national_insurance_number: claim.national_insurance_number,
            bank_sort_code: "111213",
            bank_account_number: claim.bank_account_number,
            student_loan_plan: claim.student_loan_plan,
            student_loan_repayment_amount: claim.eligibility.student_loan_repayment_amount,
            "date_of_birth(3i)": claim.date_of_birth.day,
            "date_of_birth(2i)": claim.date_of_birth.month,
            "date_of_birth(1i)": claim.date_of_birth.year,
            address_line_1: claim.address_line_1,
            address_line_2: claim.address_line_2,
            address_line_3: claim.address_line_3,
            address_line_4: "",
            postcode: claim.postcode,
            notes: "Claimant made a typo"
          }
        }

        post admin_claim_amendments_url(claim, request_params)

        expect(response).to redirect_to(admin_claim_tasks_url(claim))
        expect(claim.reload.amendments.last.claim_changes).to eq({"bank_sort_code" => ["010203", "111213"]})
      end

      it "displays a validation error and does not update the claim or create an amendment when invalid values are entered" do
        request_params = {
          amendment: {
            teacher_reference_number: "654321",
            national_insurance_number: claim.national_insurance_number,
            bank_sort_code: "111213",
            bank_account_number: "",
            student_loan_plan: claim.student_loan_plan,
            student_loan_repayment_amount: claim.eligibility.student_loan_repayment_amount,
            "date_of_birth(3i)": claim.date_of_birth.day,
            "date_of_birth(2i)": claim.date_of_birth.month,
            "date_of_birth(1i)": claim.date_of_birth.year,
            address_line_1: claim.address_line_1,
            address_line_2: claim.address_line_2,
            address_line_3: claim.address_line_3,
            address_line_4: "",
            postcode: claim.postcode,
            notes: "Claimant made a typo"
          }
        }

        expect {
          post admin_claim_amendments_url(claim, request_params)
        }.not_to change { [claim.eligibility.reload.teacher_reference_number, claim.amendments.size] }

        expect(response).to have_http_status(:ok)

        expect(response.body).to include("Teacher reference number must be 7 digits")
        expect(response.body).to include("Enter an account number")
      end

      it "displays an error message and does not create an amendment when none of the claim’s values are changed" do
        request_params = {
          amendment: {
            teacher_reference_number: claim.eligibility.teacher_reference_number,
            national_insurance_number: claim.national_insurance_number,
            bank_sort_code: claim.bank_sort_code,
            bank_account_number: claim.bank_account_number,
            student_loan_plan: claim.student_loan_plan,
            student_loan_repayment_amount: claim.eligibility.student_loan_repayment_amount,
            "date_of_birth(3i)": claim.date_of_birth.day,
            "date_of_birth(2i)": claim.date_of_birth.month,
            "date_of_birth(1i)": claim.date_of_birth.year,
            address_line_1: claim.address_line_1,
            address_line_2: claim.address_line_2,
            address_line_3: claim.address_line_3,
            address_line_4: claim.address_line_4,
            postcode: claim.postcode,
            notes: "Claimant made a typo"
          }
        }

        expect {
          post admin_claim_amendments_url(claim, request_params)
        }.not_to change { [claim.eligibility.reload.teacher_reference_number, claim.amendments.size] }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("To amend the claim you must change at least one value")
      end

      it "does not create an amendment or update the claim when attempting to modify an attribute that isn't in the allowed list" do
        original_counts = [claim.reference, claim.amendments.size]

        post admin_claim_amendments_url(claim, amendment: {claim: {reference: "REF12345"},
                                                           notes: "Claimant made a typo"})

        expect([claim.reference, claim.amendments.size]).to eq(original_counts)
      end

      context "when the claim is not amendable" do
        let(:payment) { create(:payment, :with_figures) }
        let(:claim) { create(:claim, :approved, payments: [payment]) }

        it "shows an error" do
          post admin_claim_amendments_url(claim, amendment: {claim: {eligibility_attributes: {teacher_reference_number: claim.eligibility.teacher_reference_number}},
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
            post admin_claim_amendments_url(claim, amendment: {claim: {eligibility_attributes: {teacher_reference_number: "7654321"}}})
          }.not_to change { [claim.eligibility.reload.teacher_reference_number, claim.amendments.size] }

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
