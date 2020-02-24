require "rails_helper"

RSpec.describe "Admin checks", type: :request do
  let(:claim) { create(:claim, :submitted) }

  context "when signed in as a service operator" do
    let(:user) { create(:dfe_signin_user) }

    before do
      sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
    end

    describe "checks#index" do
      it "shows a list of checks for a claim" do
        get admin_claim_checks_path(claim_id: claim.id)

        expect(response.body).to include(claim.reference)
        expect(response.body).to include("Qualifications")
        expect(response.body).to include("Employment")
      end
    end

    # Compatible with claims from each policy
    Policies.all.each do |policy|
      context "with a #{policy} claim" do
        let(:claim) { create(:claim, :submitted, policy: policy) }

        describe "checks#show" do
          it "renders the requested page" do
            get admin_claim_check_path(claim, "qualifications")
            expect(response.body).to include(I18n.t("admin.qts_award_year"))
            expect(response.body).to include(I18n.t("#{claim.policy.to_s.underscore}.questions.qts_award_years.#{claim.eligibility.qts_award_year}"))

            get admin_claim_check_path(claim, "employment")
            expect(response.body).to include(I18n.t("admin.current_school"))
            expect(response.body).to include(claim.eligibility.current_school.name)
          end
        end

        describe "checks#create" do
          it "creates a new check and redirects to the next check" do
            expect {
              post admin_claim_checks_path(claim, check: "qualifications")
            }.to change { Check.count }.by(1)

            expect(claim.checks.last.name).to eql("qualifications")
            expect(claim.checks.last.created_by).to eql(user)
            expect(response).to redirect_to(admin_claim_check_path(claim, check: "employment"))
          end

          context "when the last check is marked as completed" do
            let(:last_check) { Admin::ChecksController::CHECKS_SEQUENCE.last }

            it "creates the check and redirects to the claims#show page" do
              expect {
                post admin_claim_checks_path(claim, check: last_check)
              }.to change { Check.count }.by(1)

              expect(claim.checks.last.name).to eql(last_check)
              expect(claim.checks.last.created_by).to eql(user)
              expect(response).to redirect_to(admin_claim_path(claim))
            end
          end

          context "when a check has already been marked as completed" do
            it "doesn't create a check and redirects with an error" do
              create(:check, name: "qualifications", claim: claim)

              expect {
                post admin_claim_checks_path(claim, check: "qualifications")
              }.not_to change { Check.count }

              expect(response).to redirect_to(admin_claim_check_path(claim, check: "qualifications"))
              expect(flash[:alert]).to eql("This check has already been completed")
            end
          end
        end
      end
    end
  end

  context "when signed in as a payroll operator or a support agent" do
    describe "checks#index" do
      [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
        it "does not allow the claim checks to be viewed" do
          sign_in_to_admin_with_role(role)
          get admin_claim_checks_path(claim_id: claim.id)

          expect(response.code).to eq("401")
        end
      end
    end
  end
end
