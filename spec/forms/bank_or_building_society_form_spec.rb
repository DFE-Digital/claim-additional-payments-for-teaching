require "rails_helper"

RSpec.describe BankOrBuildingSocietyForm, type: :model do
  shared_examples "bank_or_building_society_form" do |journey|
    before {
      create(:journey_configuration, :student_loans)
      create(:journey_configuration, :additional_payments)
    }

    let(:journey_session) do
      create(
        :"#{journey::I18N_NAMESPACE}_session",
        answers: attributes_for(
          :"#{journey::I18N_NAMESPACE}_answers",
          :with_bank_details,
          building_society_roll_number: "A123456"
        )
      )
    end

    let(:slug) { "bank-or-building-society-form" }
    let(:claim_params) { {} }

    subject(:form) do
      described_class.new(
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
        let(:claim_params) { {bank_or_building_society: "personal_bank_account"} }

        it "saves bank_or_building_society" do
          expect(form.save).to be true

          expect(
            journey_session.reload.answers.bank_or_building_society
          ).to eq "personal_bank_account"
        end
      end

      context "when bank_or_building_society has not changed" do
        let(:claim_params) { {bank_or_building_society: "personal_bank_account"} }

        it "doesn't reset dependent answers" do
          expect { expect(form.save).to be true }.to(
            not_change { journey_session.reload.answers.banking_name }.and(
              not_change { journey_session.reload.answers.bank_account_number }
            ).and(
              not_change { journey_session.reload.answers.bank_sort_code }
            ).and(
              not_change { journey_session.reload.answers.building_society_roll_number }
            )
          )
        end
      end

      context "when bank_or_building_society has changed" do
        let(:claim_params) { {bank_or_building_society: "building_society"} }

        it "resets dependent answers" do
          expect { expect(form.save).to be true }.to(
            change { journey_session.reload.answers.banking_name }.to(nil).and(
              change { journey_session.reload.answers.bank_account_number }.to(nil)
            ).and(
              change { journey_session.reload.answers.bank_sort_code }.to(nil)
            ).and(
              change { journey_session.reload.answers.building_society_roll_number }.to(nil)
            )
          )
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
