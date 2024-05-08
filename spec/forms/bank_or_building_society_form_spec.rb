require "rails_helper"

RSpec.describe BankOrBuildingSocietyForm, type: :model do
  shared_examples "bank_or_building_society_form" do |journey|
    before {
      create(:journey_configuration, :student_loans)
      create(:journey_configuration, :additional_payments)
    }

    let(:current_claim) do
      claims = journey::POLICIES.map { |policy| create(:claim, policy: policy) }
      CurrentClaim.new(claims:)
    end

    let(:slug) { "bank-or-building-society-form" }
    let(:claim_params) { {} }

    subject(:form) { described_class.new(claim: current_claim, journey: journey, params: ActionController::Parameters.new({slug:, claim: claim_params})) }

    describe "validations" do
      it { should allow_value(%w[personal_bank_account building_society]).for(:bank_or_building_society).with_message("Select if you want the money paid in to a personal bank account or building society") }
    end

    describe "#save" do
      context "when submitted with valid params" do
        let(:claim_params) { {bank_or_building_society: "personal_bank_account"} }

        it "saves bank_or_building_society" do
          expect(form.save).to be true

          current_claim.claims.each do |claim|
            expect(claim.bank_or_building_society).to eq "personal_bank_account"
          end
        end
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples "bank_or_building_society_form", Journeys::TeacherStudentLoanReimbursement
  end

  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples "bank_or_building_society_form", Journeys::AdditionalPaymentsForTeaching
  end
end
