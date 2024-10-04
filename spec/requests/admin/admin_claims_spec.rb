require "rails_helper"

RSpec.describe "Admin claims", type: :request do
  before do
    create(:journey_configuration, :student_loans)
    create(:journey_configuration, :additional_payments)
    sign_in_as_service_operator
  end

  describe "claims#index" do
    let!(:claims) { create_list(:claim, 3, :submitted) }
    let!(:approved_claim) { create :claim, :approved }

    let!(:mary) { create(:dfe_signin_user, given_name: "mary", family_name: "wasu-wabi", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
    let!(:valentino) { create(:dfe_signin_user, given_name: "Valentino", family_name: "Ricci", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
    let!(:mette) { create(:dfe_signin_user, given_name: "Mette", family_name: "Jørgensen", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
    let!(:raj) { create(:dfe_signin_user, given_name: "raj", family_name: "sathikumar", organisation_name: "DfE Payroll", role_codes: [DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }

    it "lists all claims awaiting a decision" do
      get admin_claims_path

      claims.each do |c|
        expect(response.body).to include(c.reference)
      end
      expect(response.body).not_to include(approved_claim.reference)
    end

    it "can filter by policy" do
      early_career_payments_claims = create_list(:claim, 3, :submitted, policy: Policies::EarlyCareerPayments)
      get admin_claims_path, params: {filter: {policy: "early-career-payments"}}

      early_career_payments_claims.each do |c|
        expect(response.body).to include(c.reference)
      end

      claims.each do |c|
        expect(response.body).to_not include(c.reference)
      end
    end

    it "returns all claims if a policy does not exist" do
      early_career_payments_claims = create_list(:claim, 3, :submitted, policy: Policies::EarlyCareerPayments)

      get admin_claims_path, params: {policy: "non-existent-policy"}

      early_career_payments_claims.each do |c|
        expect(response.body).to include(c.reference)
      end

      claims.each do |c|
        expect(response.body).to include(c.reference)
      end
    end

    it "can filter by team member" do
      student_loans_claims_for_mette = create_list(:claim, 3, :submitted, policy: Policies::StudentLoans)
      student_loans_claims_for_valentino = create_list(:claim, 2, :submitted, policy: Policies::StudentLoans)
      early_career_payments_claims_for_mary = create_list(:claim, 4, :submitted, policy: Policies::EarlyCareerPayments)
      early_career_payments_claims_for_mette = create_list(:claim, 6, :submitted, policy: Policies::EarlyCareerPayments)

      student_loans_claims_for_mette.each { |c|
        c.assigned_to = mette
        c.save
      }
      student_loans_claims_for_valentino.each { |c|
        c.assigned_to = valentino
        c.save
      }
      early_career_payments_claims_for_mary.each { |c|
        c.assigned_to = mary
        c.save
      }
      early_career_payments_claims_for_mette.each { |c|
        c.assigned_to = mette
        c.save
      }

      get admin_claims_path, params: {filter:{team_member: mette.id}}

      [
        student_loans_claims_for_mette,
        early_career_payments_claims_for_mette
      ].flatten.each do |c|
        expect(response.body).to include(c.reference)
      end

      [
        claims,
        student_loans_claims_for_valentino,
        early_career_payments_claims_for_mary
      ].flatten.each do |c|
        expect(response.body).to_not include(c.reference)
      end
    end
  end

  # Compatible with claims from each policy
  [Policies::StudentLoans, Policies::EarlyCareerPayments, Policies::LevellingUpPremiumPayments].each do |policy|
    context "with a #{policy} claim" do
      describe "claims#show" do
        let(:claim) { create(:claim, :submitted, policy: policy) }

        it "displays the claim and eligibility details" do
          get admin_claim_path(claim)

          claim.policy::EligibilityAdminAnswersPresenter.new(claim.eligibility).answers.each do |answer|
            expect(response.body).to include(answer.first)
            expect(response.body).to include(answer.last)
          end
        end

        context "when another claim has matching attributes" do
          let!(:claim_with_matching_attributes) { create(:claim, :submitted, eligibility_attributes: {teacher_reference_number: claim.eligibility.teacher_reference_number}, policy: policy) }

          it "returns the claim and the duplicate" do
            get admin_claim_path(claim)

            expect(response.body).to include(claim.reference)
            expect(response.body).to include(claim_with_matching_attributes.reference)
          end
        end

        context "when the claim is amendable" do
          let(:claim) { create(:claim, :submitted) }

          it "displays a link to amend the claim" do
            get admin_claim_path(claim)

            expect(response.body).to include("Amend claim")
          end
        end

        context "when the claim is not amendable" do
          let(:payment) { create(:payment, :with_figures) }
          let(:claim) { create(:claim, :approved, payments: [payment]) }

          it "does not display a link to amend the claim" do
            get admin_claim_path(claim)

            expect(response.body).not_to include("Amend claim")
          end
        end
      end
    end
  end

  describe "claims#search" do
    let!(:claim1) { create(:claim, :submitted, surname: "Wayne") }
    let!(:claim2) { create(:claim, :submitted, surname: "Wayne") }

    it "redirects to a claim when one exists" do
      get search_admin_claims_path(query: claim1.reference)

      expect(response).to redirect_to(admin_claim_tasks_path(claim1))
    end

    it "shows a list of matching claims if there are more than one" do
      get search_admin_claims_path(query: "Wayne")

      expect(response.body).to include(claim1.reference)
      expect(response.body).to include(claim2.reference)
    end

    it "shows an error if a claim can't be found" do
      reference = "12345678"
      get search_admin_claims_path(query: reference)

      expected_flash = CGI.escapeHTML("Cannot find a claim for query \"#{reference}\"")
      expect(response.body).to include(expected_flash)
    end
  end

  describe "claims#hold" do
    let!(:claim) { create(:claim, :submitted) }

    it "gracefully handles duplicate submissions" do
      patch admin_claim_hold_path(claim, params: {hold: {body: "test"}})
      patch admin_claim_hold_path(claim, params: {hold: {body: "test"}})

      expect(claim.reload.notes.count).to eq(1)
    end
  end

  describe "claims#unhold" do
    let!(:claim) { create(:claim, :submitted, :held) }

    it "gracefully handles duplicate submissions" do
      patch admin_claim_unhold_path(claim)
      patch admin_claim_unhold_path(claim)

      expect(claim.reload.notes.count).to eq(1)
    end
  end
end
