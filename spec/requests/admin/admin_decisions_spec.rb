require "rails_helper"

RSpec.describe "Admin decisions", type: :request do
  context "when signed in as a service operator" do
    let(:claim) { create(:claim, :submitted, policy: Policies::EarlyCareerPayments) }

    before do
      create(:journey_configuration, :early_career_payments)
      @signed_in_user = sign_in_as_service_operator
    end

    describe "decisions#new" do
      it "renders the claim decision form" do
        get new_admin_claim_decision_path(claim)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Claim decision")
      end

      context "when all tasks have been completed" do
        before do
          create(:task, name: "identity_confirmation", claim: claim)
          create(:task, name: "qualifications", claim: claim)
          create(:task, name: "induction_confirmation", claim: claim)
          create(:task, name: "student_loan_plan", claim: claim)
          create(:task, name: "census_subjects_taught", claim: claim)
          create(:task, name: "employment", claim: claim)
        end

        it "does not warn the service operator about incomplete tasks" do
          get new_admin_claim_decision_path(claim)

          expect(response).to have_http_status(:ok)
          expect(response.body).not_to include("Some tasks have not yet been completed")
        end
      end

      context "when some tasks have not been completed" do
        let(:claim) {
          create(:claim, :submitted, policy: Policies::EarlyCareerPayments, tasks: [
            build(:task, name: "qualifications")
          ])
        }

        it "warns the service operator about those tasks" do
          get new_admin_claim_decision_path(claim)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Some tasks have not yet been completed")
          expect(response.body).to include("Check employment information")
          expect(response.body).to include(admin_claim_task_url(claim, name: "employment"))
        end
      end

      context "when a decision has already been made" do
        let(:claim) { create(:claim, :approved, policy: Policies::EarlyCareerPayments) }

        it "redirects and shows an error" do
          get new_admin_claim_decision_path(claim)

          expect(response).to redirect_to(admin_claim_path(claim))
          expect(flash[:notice]).to eql("Claim outcome already decided")
        end
      end
    end

    describe "decisions#create" do
      before do
        deliver_mock = double(deliver_later: nil)
        allow(ClaimMailer).to receive(:approved).and_return(deliver_mock)
        allow(ClaimMailer).to receive(:rejected).and_return(deliver_mock)
      end

      context "when a claim is being flagged for QA" do
        it "can approve the claim and flag it for QA", :aggregate_failures do
          post admin_claim_decisions_path(claim_id: claim.id, decision: {approved: true})

          follow_redirect!

          expect(response.body).to include("This claim has been marked for a quality assurance review")
          expect(response.body).to include("Claim has been approved successfully")

          expect(ClaimMailer).not_to have_received(:approved).with(claim)

          expect(claim.latest_decision.created_by).to eq(@signed_in_user)
          expect(claim.latest_decision).to be_approved

          expect(claim.reload.qa_required).to eq(true)
          expect(claim.reload.qa_completed_at).to be_nil
          expect(claim.reload.notes.last.body).to eq("This claim has been marked for a quality assurance review")
        end

        context "when adding a QA decision" do
          let(:claim) { create(:claim, :approved, :flagged_for_qa, policy: Policies::StudentLoans) }

          it "can undo the previous decision and approve the claim", :aggregate_failures do
            post admin_claim_decisions_path(qa: true, claim_id: claim.id, decision: {approved: true})

            follow_redirect!

            expect(response.body).not_to include("This claim has been marked for a quality assurance review")
            expect(response.body).to include("Claim has been approved successfully")

            expect(ClaimMailer).to have_received(:approved).with(claim)

            expect(claim.previous_decision.undone).to eq(true)
            expect(claim.latest_decision.created_by).to eq(@signed_in_user)
            expect(claim.latest_decision).to be_approved
            expect(claim.reload.qa_completed_at).not_to be_nil
          end

          it "can undo the previous decision and reject a claim", :aggregate_failures do
            post admin_claim_decisions_path(qa: true, claim_id: claim.id, decision: {approved: false, rejected_reasons_ineligible_subject: "1"})

            follow_redirect!

            expect(response.body).to include("Claim has been rejected successfully")

            expect(ClaimMailer).to have_received(:rejected).with(claim)

            expect(claim.previous_decision.undone).to eq(true)
            expect(claim.latest_decision.created_by).to eq(@signed_in_user)
            expect(claim.latest_decision).to be_rejected
            expect(claim.reload.qa_completed_at).not_to be_nil
          end
        end
      end

      context "when a claim is not being flagged for QA" do
        before { disable_claim_qa_flagging }

        it "can approve the claim", :aggregate_failures do
          post admin_claim_decisions_path(claim_id: claim.id, decision: {approved: true})

          follow_redirect!

          expect(response.body).to include("Claim has been approved successfully")

          expect(ClaimMailer).to have_received(:approved).with(claim)

          expect(claim.latest_decision.created_by).to eq(@signed_in_user)
          expect(claim.latest_decision).to be_approved
        end

        it "can reject the claim", :aggregate_failures do
          post admin_claim_decisions_path(claim_id: claim.id, decision: {approved: false, rejected_reasons_ineligible_subject: "1"})

          follow_redirect!

          expect(response.body).to include("Claim has been rejected successfully")

          expect(ClaimMailer).to have_received(:rejected).with(claim)

          expect(claim.latest_decision.created_by).to eq(@signed_in_user)
          expect(claim.latest_decision).to be_rejected
        end
      end

      context "when no result is selected" do
        it "shows an error and doesn't save the decision" do
          post admin_claim_decisions_path(claim_id: claim.id, decision: {notes: "Something"})

          expect(response.body).to include("Make a decision to approve or reject the claim")
          expect(claim.reload.latest_decision).to be_nil
        end
      end

      context "when a decision has already been made" do
        let(:claim) { create(:claim, :approved, policy: Policies::EarlyCareerPayments) }

        it "shows an error" do
          post admin_claim_decisions_path(claim_id: claim.id, decision: {approved: true})

          follow_redirect!

          expect(response.body).to include("Claim outcome already decided")
        end
      end

      context "when a QA decision has already been made" do
        let(:claim) { create(:claim, :approved, :qa_completed, policy: Policies::EarlyCareerPayments) }

        it "shows an error" do
          post admin_claim_decisions_path(qa: true, claim_id: claim.id, decision: {approved: true})

          follow_redirect!

          expect(response.body).to include("Claim outcome already decided")
        end
      end

      context "when the claim is missing a payroll gender" do
        let(:claim) { create(:claim, :submitted, payroll_gender: :dont_know, policy: Policies::EarlyCareerPayments) }

        before do
          post admin_claim_decisions_path(claim_id: claim.id, decision: {approved: approved, rejected_reasons_ineligible_subject: "1"})
          follow_redirect!
        end

        context "and the user attempts to approve" do
          let(:approved) { true }

          it "shows an error" do
            expect(response.body).to include("Claim cannot be approved")
          end
        end

        context "and the user attempts to reject" do
          let(:approved) { false }

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
            eligibility_attributes: {teacher_reference_number: generate(:teacher_reference_number)},
            date_of_birth: 30.years.ago.to_date,
            student_loan_plan: StudentLoan::PLAN_1,
            email_address: "email@example.com",
            bank_sort_code: "112233",
            bank_account_number: "95928482",
            building_society_roll_number: nil
          }
        end
        let(:claim) { create(:claim, :submitted, personal_details.merge(bank_sort_code: "582939", bank_account_number: "74727752", policy: Policies::EarlyCareerPayments)) }
        let!(:approved_claim) { create(:claim, :approved, personal_details.merge(bank_sort_code: "112233", bank_account_number: "29482823", policy: Policies::EarlyCareerPayments)) }

        before do
          post admin_claim_decisions_path(claim_id: claim.id, decision: {approved: approved, rejected_reasons_ineligible_subject: "1"})
          follow_redirect!
        end

        context "and the user attempts to approve" do
          let(:approved) { true }
          it "shows an error" do
            expect(response.body).to include("Claim cannot be approved because there are inconsistent claims")
          end
        end

        context "and the user attempts to reject" do
          let(:approved) { false }
          it "doesn’t show an error and rejects successfully" do
            expect(response.body).not_to include("Claim cannot be approved")
            expect(response.body).to include("Claim has been rejected successfully")
          end
        end
      end
    end
  end

  context "when signed in as a payroll operator or a support agent" do
    describe "decisions#create" do
      let(:claim) { create(:claim, :submitted) }

      [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
        it "does not allow a claim to be approved" do
          sign_in_to_admin_with_role(role)
          post admin_claim_decisions_path(claim_id: claim.id, approved: true)

          expect(response.code).to eq("401")
        end
      end
    end
  end
end
