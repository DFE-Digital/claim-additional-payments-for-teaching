require "rails_helper"

RSpec.describe GenderForm do
  shared_examples "gender_form" do |journey|
    before { create(:journey_configuration, :targeted_retention_incentive_payments) }

    let(:journey_session) do
      create(
        :"#{journey::I18N_NAMESPACE}_session",
        answers: {
          payroll_gender: gender
        }
      )
    end

    let(:gender) { nil }

    let(:slug) { "gender" }

    subject(:form) do
      described_class.new(
        journey_session: journey_session,
        journey: journey,
        params: params
      )
    end

    describe "#payroll_gender" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}}) }

      context "claim payroll_gender DOES NOT have a current value" do
        it "returns nil" do
          expect(form.payroll_gender).to be_nil
        end
      end

      context "claim payroll_gender DOES have a current value" do
        let(:gender) { "male" }

        it "returns the current value" do
          expect(form.payroll_gender).to eq "male"
        end
      end
    end

    describe "#save" do
      context "payroll_gender submitted" do
        let(:params) { ActionController::Parameters.new({slug: slug, claim: {payroll_gender: "female"}}) }

        context "claim didn't have payroll_gender" do
          it "updates the payroll_gender on claim" do
            expect(form.save).to be true

            expect(journey_session.reload.answers.payroll_gender).to eq "female"
          end
        end

        context "claim already had a payroll_gender" do
          let(:gender) { "dont_know" }

          it "updates the payroll_gender on claim" do
            expect(form.save).to be true

            expect(journey_session.reload.answers.payroll_gender).to eq "female"
          end
        end
      end

      context "payroll_gender missing" do
        let(:params) { ActionController::Parameters.new({slug: slug, claim: {payroll_gender: ""}}) }

        it "does not save and adds error to form" do
          expect(form.save).to be false
          expect(form.errors[:payroll_gender]).to eq ["Select the gender recorded on your school’s payroll system or select whether you do not know"]
        end
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples "gender_form", Journeys::TeacherStudentLoanReimbursement
  end

  describe "for TargetedRetentionIncentivePayments journey" do
    include_examples "gender_form", Journeys::TargetedRetentionIncentivePayments
  end
end
