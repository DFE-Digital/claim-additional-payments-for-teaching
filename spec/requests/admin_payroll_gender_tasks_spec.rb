require "rails_helper"

RSpec.describe "Admin tasks", type: :request do
  let(:claim) { create(:claim, :submitted) }

  context "when signed in as a service operator" do
    before { @signed_in_user = sign_in_as_service_operator }

    Policies.all.each do |policy|
      context "with a #{policy} claim" do
        describe "payroll_gender_tasks#create" do
          let(:claim) { create(:claim, :submitted, policy: policy, payroll_gender: :dont_know) }
          let(:params) {
            {
              claim: {
                payroll_gender: "male"
              },
              task: {
                passed: true
              }
            }
          }

          it "updates the claimant's payroll gender, creates a task and redirects to the decision page" do
            expect {
              post admin_claim_payroll_gender_tasks_path(claim, params: params)
            }.to change { Task.count }.by(1)

            expect(claim.reload.payroll_gender).to eq("male")
            expect(claim.tasks.last.name).to eql("payroll_gender")
            expect(claim.tasks.last.passed?).to eql(true)
            expect(claim.tasks.last.created_by).to eql(@signed_in_user)
            expect(response).to redirect_to(new_admin_claim_decision_path(claim))
          end

          context "when a payroll gender is not set" do
            it "doesn't create a task and shows an error" do
              pending("# Implement EarlyCareerPayments Admin Journey") if policy == EarlyCareerPayments
              # FIXME ADMIN Sections for EarlyCareerPayments

              params[:claim][:payroll_gender] = ""

              expect {
                post admin_claim_payroll_gender_tasks_path(claim, params: params)
              }.not_to change { claim.tasks.count }

              expect(response.body).to match("You must select a gender that will be passed to HMRC")
            end
          end

          context "when the task has already been marked as completed" do
            it "doesn't create a task, or update the gender and redirects with an error" do
              create(:task, name: "payroll_gender", claim: claim)
              claim.payroll_gender = "female"
              claim.save

              expect {
                post admin_claim_payroll_gender_tasks_path(claim, params: params)
              }.not_to change { claim.tasks.count }

              expect(response).to redirect_to(admin_claim_task_path(claim, name: "payroll_gender"))
              expect(flash[:alert]).to eql("This task has already been completed")
              expect(claim.reload.payroll_gender).to eq("female")
            end
          end
        end
      end
    end
  end

  context "when signed in as a payroll operator or a support agent" do
    describe "payroll_gender_tasks#create" do
      [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
        it "does not allow the task to be created" do
          sign_in_to_admin_with_role(role)
          post admin_claim_tasks_path(claim_id: claim.id)

          expect(response.code).to eq("401")
        end
      end
    end
  end
end
