require "rails_helper"

RSpec.describe ProvideMobileNumberForm, type: :model do
  shared_examples "provide_mobile_number_form" do |journey|
    before {
      create(:journey_configuration, :student_loans)
      create(:journey_configuration, :additional_payments)
    }

    let(:current_claim) do
      claims = journey::POLICIES.map { |policy| create(:claim, policy: policy) }
      CurrentClaim.new(claims: claims)
    end

    let(:slug) { "provide-mobile-number" }
    let(:params) { ActionController::Parameters.new }
    let(:journey_session) do
      build(:journeys_session, journey: journey::ROUTING_NAME)
    end

    subject(:form) do
      described_class.new(
        claim: current_claim,
        journey_session: journey_session,
        journey: journey,
        params: params
      )
    end

    context "unpermitted claim param" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {nonsense_id: 1}}) }

      it "raises an error" do
        expect { form }.to raise_error ActionController::UnpermittedParameters
      end
    end

    describe "validations" do
      it { should allow_value(%w[true false]).for(:provide_mobile_number).with_message("Select yes if you would like to provide your mobile number") }
    end

    describe "#save" do
      context "when submitted with valid params" do
        let(:params) { ActionController::Parameters.new({slug: slug, claim: {provide_mobile_number: "Yes"}}) }

        context "when claim is missing provide_mobile_number" do
          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy: policy) }
            CurrentClaim.new(claims: claims)
          end

          it "saves provide_mobile_number" do
            expect(form.save).to be true

            current_claim.claims.each do |claim|
              expect(claim.provide_mobile_number).to be_truthy
            end
          end
        end

        context "claim already has provide_mobile_number" do
          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy: policy, provide_mobile_number: false) }
            CurrentClaim.new(claims: claims)
          end

          it "updates provide_mobile_number on claim" do
            expect(form.save).to be true

            current_claim.claims.each do |claim|
              expect(claim.provide_mobile_number).to be_truthy
            end
          end
        end
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples "provide_mobile_number_form", Journeys::TeacherStudentLoanReimbursement
  end

  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples "provide_mobile_number_form", Journeys::AdditionalPaymentsForTeaching
  end
end
