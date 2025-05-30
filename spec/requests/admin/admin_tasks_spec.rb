require "rails_helper"

RSpec.describe "Admin tasks", type: :request do
  let(:claim) { create(:claim, :submitted) }

  before do
    create(:journey_configuration, :student_loans)
    create(:journey_configuration, :targeted_retention_incentive_payments)
  end

  context "when signed in as a service operator" do
    before do
      @signed_in_user = sign_in_as_service_operator
    end

    describe "tasks#index" do
      it "shows a list of tasks for a claim" do
        get admin_claim_tasks_path(claim_id: claim.id)

        expect(response.body).to include(claim.reference)
        expect(response.body).to include("Qualifications")
        expect(response.body).to include("Employment")
      end

      context "when the claim has a decision" do
        let(:claim) { create(:claim, :approved) }

        it "shows the outcome of the decision" do
          get admin_claim_tasks_path(claim_id: claim.id)

          expect(response.body).to include("Approved")
        end
      end
    end

    # Compatible with claims from each policy
    [Policies::StudentLoans, Policies::TargetedRetentionIncentivePayments].each do |policy|
      context "with a #{policy} claim" do
        let(:claim) { create(:claim, :submitted, policy: policy) }

        describe "tasks#show" do
          it "renders the requested page" do
            get admin_claim_task_path(claim, "employment")
            expect(response.body).to include(I18n.t("admin.current_school"))
            expect(response.body).to include(claim.eligibility.current_school.name)
          end
        end

        describe "tasks#create" do
          it "creates a new passed task and redirects to the next task", if: policy == Policies::StudentLoans do
            expect {
              post admin_claim_tasks_path(claim, params: {task: {name: "qualifications", passed: "true"}})
            }.to change { Task.count }.by(1)

            expect(claim.tasks.last.name).to eql("qualifications")
            expect(claim.tasks.last.passed?).to eql(true)
            expect(claim.tasks.last.created_by).to eql(@signed_in_user)
            expect(response).to redirect_to(admin_claim_task_path(claim, name: "census_subjects_taught"))
          end

          it "creates a new failed task" do
            post admin_claim_tasks_path(claim, params: {task: {name: "qualifications", passed: "false"}})

            expect(claim.tasks.last.name).to eql("qualifications")
            expect(claim.tasks.last.passed?).to eql(false)
          end

          context "when the last task is marked as completed" do
            let(:last_task) { ClaimCheckingTasks.new(claim).applicable_task_names.last }

            it "creates the task and redirects to the decision page" do
              expect {
                post admin_claim_tasks_path(claim, params: {task: {name: last_task, passed: "true"}})
              }.to change { Task.count }.by(1)

              expect(claim.tasks.reload.last.name).to eql(last_task)
              expect(claim.tasks.last.passed?).to eql(true)
              expect(claim.tasks.last.created_by).to eql(@signed_in_user)
              expect(response).to redirect_to(new_admin_claim_decision_path(claim))
            end
          end

          context "when a task's passed flag is not set" do
            it "doesn't create a task and shows an error" do
              expect {
                post admin_claim_tasks_path(claim, params: {task: {name: "qualifications", passed: ""}})
              }.not_to change { claim.tasks.count }

              expect(response.body).to match("You must select ‘Yes’ or ‘No’")
            end
          end

          context "when a task has already been marked as completed" do
            it "doesn't create a task and redirects with an error" do
              create(:task, name: "qualifications", claim: claim)

              expect {
                post admin_claim_tasks_path(claim, params: {task: {name: "qualifications", passed: "true"}})
              }.not_to change { Task.count }

              expect(response).to redirect_to(admin_claim_task_path(claim, name: "qualifications"))
              expect(flash[:alert]).to eql("This task has already been completed")
            end
          end
        end
      end
    end

    context "with an International Relocation Payments claim" do
      let(:claim) { create(:claim, :submitted, policy: Policies::InternationalRelocationPayments) }

      describe "tasks#show" do
        it "renders the requested page" do
          get admin_claim_task_path(claim, "identity_confirmation")
          expect(response.body).to include(I18n.t("admin.nationality"))
          expect(response.body).to include(I18n.t("admin.passport_number"))
        end
      end
    end
  end

  context "when signed in as a support agent" do
    describe "tasks#index" do
      it "does not allow the claim tasks to be viewed" do
        sign_in_to_admin_with_role(DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)
        get admin_claim_tasks_path(claim_id: claim.id)

        expect(response.code).to eq("401")
      end
    end
  end
end
