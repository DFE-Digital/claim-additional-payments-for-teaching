require "rails_helper"

RSpec.describe "Admin claim allocations", type: :request do
  describe "PATCH /admin/claims/bulk_deallocate" do
    let(:call_endpoint) do
      patch admin_bulk_deallocate_path, params: params
    end
    let(:params) do
      {
        allocate_to_team_member: team_member.id,
        allocate_to_policy: allocation_policy,
        user_confirmation: user_confirmation
      }
    end
    let(:team_member) { create(:dfe_signin_user, :service_operator) }
    let(:user_confirmation) { "yes" }
    let(:allocation_policy) { "" }

    before do
      sign_in_as_service_operator if authenticated
    end

    context "when unauthenticated" do
      let(:authenticated) { false }

      before { call_endpoint }

      it { expect(response).to redirect_to(admin_sign_in_path) }
    end

    shared_examples :flashing_relevant_message do |translation|
      let(:expected_message) do
        I18n.t(translation,
          allocate_to_policy: allocation_policy.titleize,
          dfe_user: team_member.full_name.titleize)
      end

      before do
        call_endpoint
        follow_redirect!
      end

      it "flashes the #{translation} message" do
        expect(response.body).to include(expected_message)
      end
    end

    context "when authenticated as service operator" do |translation|
      let(:authenticated) { true }

      context "when the request does not contain confirmation" do
        let(:user_confirmation) { "" }

        before { call_endpoint }

        let(:expected_question) do
          I18n.t("admin.allocations.bulk_deallocate.confirmation",
            allocate_to_policy: allocation_policy&.titleize,
            dfe_user: team_member.full_name.titleize)
        end

        it "asks the user for confirmation" do
          expect(response.body).to include(expected_question)
        end
      end

      context "when no claims can be unassigned from a team member" do
        let(:another_team_member) { create(:dfe_signin_user, :service_operator) }
        let!(:claims_assigned_to_another_team_member) do
          create_list(:claim, 3, :submitted, policy: StudentLoans, assigned_to: another_team_member)
        end

        include_examples :flashing_relevant_message, "admin.allocations.bulk_deallocate.info"
      end

      context "when claims can be unassigned from the user" do
        let(:another_team_member) { create(:dfe_signin_user, :service_operator) }
        let!(:claims_assigned_to_team_member) do
          create_list(:claim, 3, :submitted, policy: StudentLoans, assigned_to: team_member)
        end
        let!(:claims_assigned_to_another_team_member) do
          create_list(:claim, 3, :submitted, policy: StudentLoans, assigned_to: another_team_member)
        end

        before { call_endpoint }

        it "unassigns claims from the team member" do
          expect(claims_assigned_to_team_member.map(&:reload))
            .to all(have_attributes(assigned_to: nil))
        end

        it "keeps the remaining claims assigned to the other team member" do
          expect(claims_assigned_to_another_team_member.map(&:reload))
            .to all(have_attributes(assigned_to: another_team_member))
        end

        include_examples :flashing_relevant_message, "admin.allocations.bulk_deallocate.success"
      end

      context "when a policy is specified" do
        let(:allocation_policy) { "student-loans" }

        let!(:student_loans_assigned_claims) do
          create_list(:claim, 3, :submitted, policy: StudentLoans, assigned_to: team_member)
        end
        let!(:early_career_payments_assigned_claims) do
          create_list(:claim, 3, :submitted, policy: EarlyCareerPayments, assigned_to: team_member)
        end

        before { call_endpoint }

        it "unassigns the claims for that policy only", :aggregate_failures do
          expect(student_loans_assigned_claims.map(&:reload))
            .to all(have_attributes(assigned_to: nil))

          expect(early_career_payments_assigned_claims.map(&:reload))
            .to all(have_attributes(assigned_to: team_member))
        end

        include_examples :flashing_relevant_message, "admin.allocations.bulk_deallocate.success"
      end
    end
  end
end
