require "rails_helper"

RSpec.feature "Admin decisions" do
  context "when signed in as a service operator" do
    let(:claim) { create(:claim, :submitted, policy: Policies::TargetedRetentionIncentivePayments) }

    before do
      create(:journey_configuration, :targeted_retention_incentive_payments)
      @signed_in_user = sign_in_as_service_operator
    end

    describe "decisions#new" do
      it "renders the claim decision form" do
        visit new_admin_claim_decision_path(claim)

        expect(page).to have_text("Claim decision")
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
          visit new_admin_claim_decision_path(claim)

          expect(page).not_to have_text("Some tasks have not yet been completed")
        end
      end

      context "when some tasks have not been completed" do
        let(:claim) {
          create(:claim, :submitted, policy: Policies::TargetedRetentionIncentivePayments, tasks: [
            build(:task, name: "qualifications")
          ])
        }

        it "warns the service operator about those tasks" do
          visit new_admin_claim_decision_path(claim)

          expect(page).to have_text("Some tasks have not yet been completed")
          expect(page).to have_text("Check employment information")
          expect(page).to have_link("Check employment information", href: admin_claim_task_url(claim, name: "employment"))
        end
      end

      context "when a decision has already been made" do
        let(:claim) { create(:claim, :approved, policy: Policies::TargetedRetentionIncentivePayments) }

        it "redirects and shows an error" do
          visit new_admin_claim_decision_path(claim)

          expect(page.current_path).to eql(admin_claim_path(claim))
          expect(page).to have_text("Claim outcome already decided")
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
          visit admin_claim_path(claim)
          click_link "View tasks"
          click_link "Approve or reject this claim"

          choose "Approve"
          click_button "Confirm decision"

          expect(page).to have_text("This claim has been marked for a quality assurance review")
          expect(page).to have_text("Claim has been approved successfully")

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
            visit admin_claim_path(claim)
            click_link "View tasks"
            click_link "Approve or reject quality assurance of this claim"
            choose "Approve"
            click_button "Confirm decision"

            expect(page).not_to have_text("This claim has been marked for a quality assurance review")
            expect(page).to have_text("Claim has been approved successfully")

            expect(ClaimMailer).to have_received(:approved).with(claim)

            expect(claim.previous_decision.undone).to eq(true)
            expect(claim.latest_decision.created_by).to eq(@signed_in_user)
            expect(claim.latest_decision).to be_approved
            expect(claim.reload.qa_completed_at).not_to be_nil

            visit admin_claim_tasks_path(claim)
            click_link "Claim timeline"
            expect(page).to have_text("Claim approved")
          end

          it "can undo the previous decision and reject a claim", :aggregate_failures do
            visit admin_claim_path(claim)
            click_link "View tasks"
            click_link "Approve or reject quality assurance of this claim"
            choose "Reject"
            check "Ineligible subject"
            click_button "Confirm decision"

            expect(page).to have_text("Claim has been rejected successfully")

            expect(ClaimMailer).to have_received(:rejected).with(claim)

            expect(claim.previous_decision.undone).to eq(true)
            expect(claim.latest_decision.created_by).to eq(@signed_in_user)
            expect(claim.latest_decision).to be_rejected
            expect(claim.reload.qa_completed_at).not_to be_nil

            visit admin_claim_tasks_path(claim)
            click_link "Claim timeline"
            expect(page).to have_text("Claim rejected")
          end
        end
      end

      context "when a claim is not being flagged for QA" do
        before { disable_claim_qa_flagging }

        it "can approve the claim", :aggregate_failures do
          visit admin_claim_tasks_path(claim)
          click_link "Approve or reject this claim"

          choose "Approve"
          click_button "Confirm decision"

          expect(page).to have_text("Claim has been approved successfully")
          expect(ClaimMailer).to have_received(:approved).with(claim)
          expect(claim.latest_decision.created_by).to eq(@signed_in_user)
          expect(claim.latest_decision).to be_approved

          visit admin_claim_tasks_path(claim)
          click_link "Claim timeline"
          expect(page).to have_text("Claim approved")
        end

        it "can reject the claim", :aggregate_failures do
          visit admin_claim_tasks_path(claim)
          click_link "Approve or reject this claim"

          choose "Reject"
          check "Ineligible subject"
          click_button "Confirm decision"

          expect(page).to have_text("Claim has been rejected successfully")
          expect(ClaimMailer).to have_received(:rejected).with(claim)
          expect(claim.latest_decision.created_by).to eq(@signed_in_user)
          expect(claim.latest_decision).to be_rejected

          visit admin_claim_tasks_path(claim)
          click_link "Claim timeline"
          expect(page).to have_text("Claim rejected")
        end
      end

      context "when no result is selected" do
        it "shows an error and doesn't save the decision" do
          visit admin_claim_tasks_path(claim)
          click_link "Approve or reject this claim"

          fill_in "Decision notes", with: "Something"
          click_button "Confirm decision"

          expect(page).to have_text("Select if you approve or reject the claim")
          expect(claim.reload.latest_decision).to be_nil
        end
      end

      context "when a decision has already been made" do
        let(:claim) { create(:claim, :submitted, policy: Policies::TargetedRetentionIncentivePayments) }

        it "shows an error" do
          visit admin_claim_path(claim)
          click_link "View tasks"
          click_link "Approve or reject this claim"

          create(:decision, :approved, claim:)

          choose "Approve"
          click_button "Confirm decision"

          expect(page).to have_text("Claim outcome already decided")
        end
      end

      context "when a QA decision has already been made" do
        let(:claim) { create(:claim, :approved, :flagged_for_qa, policy: Policies::TargetedRetentionIncentivePayments) }

        it "shows an error" do
          visit admin_claim_path(claim)
          click_link "View tasks"
          click_link "Approve or reject quality assurance of this claim"

          claim.update(qa_completed_at: 1.second.ago)

          choose "Approve"
          click_button "Confirm decision"

          expect(page).to have_text("Claim outcome already decided")
        end
      end

      context "when the claim is missing a payroll gender" do
        let(:claim) { create(:claim, :submitted, payroll_gender: "female", policy: Policies::TargetedRetentionIncentivePayments) }

        before do
          visit admin_claim_tasks_path(claim)
          click_link "Approve or reject this claim"

          claim.update payroll_gender: nil
        end

        context "and the user attempts to approve" do
          it "shows an error" do
            choose "Approve"
            click_button "Confirm decision"

            expect(page).to have_text("Claim cannot be approved")
          end
        end

        context "and the user attempts to reject" do
          it "doesn’t show an error and rejects successfully" do
            choose "Reject"
            check "Ineligible subject"
            click_button "Confirm decision"

            expect(page).not_to have_text("Claim cannot be approved")
            expect(page).to have_text("Claim has been rejected successfully")
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
        let(:claim) { create(:claim, :submitted, personal_details.merge(bank_sort_code: "582939", bank_account_number: "74727752", policy: Policies::TargetedRetentionIncentivePayments)) }

        before do
          visit admin_claim_path(claim)
          click_link "View tasks"
          click_link "Approve or reject this claim"
        end

        context "and the user attempts to approve" do
          it "shows an error" do
            create(:claim, :approved, personal_details.merge(bank_sort_code: "112233", bank_account_number: "29482823", policy: Policies::TargetedRetentionIncentivePayments))

            choose "Approve"
            click_button "Confirm decision"
            expect(page).to have_text("Claim cannot be approved because there are inconsistent claims")
          end
        end

        context "and the user attempts to reject" do
          it "doesn’t show an error and rejects successfully" do
            create(:claim, :approved, personal_details.merge(bank_sort_code: "112233", bank_account_number: "29482823", policy: Policies::TargetedRetentionIncentivePayments))

            choose "Reject"
            check "Ineligible subject"
            click_button "Confirm decision"

            expect(page).to have_text("Claim has been rejected successfully")
          end
        end
      end
    end
  end
end
