require "rails_helper"

RSpec.describe ProvideMobileNumberForm, type: :model do
  shared_examples "provide_mobile_number_form" do |journey|
    before {
      create(:journey_configuration, :student_loans)
      create(:journey_configuration, :targeted_retention_incentive_payments)
    }

    let(:slug) { "provide-mobile-number" }

    let(:params) { ActionController::Parameters.new }

    let(:journey_session) do
      create(
        :"#{journey.i18n_namespace}_session",
        answers: {
          provide_mobile_number: provide_mobile_number,
          mobile_verified: true
        }
      )
    end

    subject(:form) do
      described_class.new(
        journey_session: journey_session,
        journey: journey,
        params: params
      )
    end

    describe "validations" do
      let(:provide_mobile_number) { nil }

      it { should allow_value(%w[true false]).for(:provide_mobile_number).with_message("Select yes if you would like to provide your mobile number") }
    end

    describe "#save" do
      context "when submitted with valid params" do
        let(:params) { ActionController::Parameters.new({slug: slug, claim: {provide_mobile_number: true}}) }

        context "when claim is missing provide_mobile_number" do
          let(:provide_mobile_number) { nil }

          it "saves provide_mobile_number" do
            expect(form.save).to be true

            expect(
              journey_session.reload.answers.provide_mobile_number
            ).to eq true
          end
        end

        context "claim already has provide_mobile_number" do
          let(:provide_mobile_number) { false }

          it "updates provide_mobile_number on claim" do
            expect(form.save).to be true

            expect(
              journey_session.reload.answers.provide_mobile_number
            ).to eq true
          end
        end

        context "when provide_mobile_number has not changed" do
          let(:provide_mobile_number) { true }

          let(:params) do
            ActionController::Parameters.new(
              claim: {
                provide_mobile_number: true
              }
            )
          end

          it "doesn't reset dependent answers" do
            form.save

            expect(journey_session.reload.answers.mobile_verified).to eq true
          end
        end

        context "when provide_mobile_number has changed" do
          let(:provide_mobile_number) { false }

          let(:params) do
            ActionController::Parameters.new(
              claim: {
                provide_mobile_number: true
              }
            )
          end

          it "resets dependent answers" do
            expect { form.save }.to(
              change { journey_session.reload.answers.mobile_verified }
              .from(true).to(nil)
            )
          end
        end
      end

      context "answering no after having previously answered yes with a mobile number" do
        let(:params) { ActionController::Parameters.new({slug: slug, claim: {provide_mobile_number: false}}) }
        let(:mobile_number) { "07700900001" }
        let(:journey_session) do
          create(
            :"#{journey.i18n_namespace}_session",
            answers: {
              provide_mobile_number: true,
              mobile_number: mobile_number,
              mobile_verified: true
            }
          )
        end

        it "resets the previously provided mobile number" do
          expect { form.save }.to change { journey_session.reload.answers.mobile_number }.from(mobile_number).to(nil)
        end
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples "provide_mobile_number_form", Journeys::TeacherStudentLoanReimbursement
  end

  describe "for TargetedRetentionIncentivePayments journey" do
    include_examples "provide_mobile_number_form", Journeys::TargetedRetentionIncentivePayments
  end
end
