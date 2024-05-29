require "rails_helper"

RSpec.describe BankOrBuildingSocietyForm, type: :model do
  shared_examples "bank_or_building_society_form" do |journey|
    before {
      create(:journey_configuration, :student_loans)
      create(:journey_configuration, :additional_payments)
    }

    let(:current_claim) do
      claims = journey::POLICIES.map do |policy|
        create(
          :claim,
          :with_bank_details,
          building_society_roll_number: "A123456",
          policy: policy,
        )
      end

      CurrentClaim.new(claims:)
    end

    let(:journey_session) { build(:"#{journey::I18N_NAMESPACE}_session") }

    let(:slug) { "bank-or-building-society-form" }
    let(:claim_params) { {} }

    subject(:form) do
      described_class.new(
        claim: current_claim,
        journey_session: journey_session,
        journey: journey,
        params: ActionController::Parameters.new({slug:, claim: claim_params})
      )
    end

    describe "validations" do
      it { should allow_value(%w[personal_bank_account building_society]).for(:bank_or_building_society).with_message("Select if you want the money paid in to a personal bank account or building society") }
    end

    describe "#save" do
      context "when submitted with valid params" do
        let(:claim_params) { {bank_or_building_society: "building_society"} }

        it "saves bank_or_building_society" do
          expect(form.save).to be true

          current_claim.claims.each do |claim|
            expect(claim.bank_or_building_society).to eq "building_society"
          end
        end

        it "resets dependent answers" do
          current_claim.claims.first(1).each do |claim|
            expect { expect(form.save).to be true }.to(
              change { claim.banking_name }.to(nil).and(
                change { claim.bank_account_number }.to(nil).and(
                  change { claim.bank_sort_code }.to(nil).and(
                    change { claim.building_society_roll_number }.to(nil)
                  )
                )
              )
            )
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
