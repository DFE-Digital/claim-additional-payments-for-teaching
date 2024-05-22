require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::InductionCompletedForm do
  shared_examples "induction_completed_form" do |journey|
    before {
      create(:journey_configuration, :additional_payments)
    }

    let(:current_claim) do
      claims = journey::POLICIES.map { |policy| create(:claim, policy: policy) }
      CurrentClaim.new(claims: claims)
    end

    let(:slug) { "induction_completed" }

    let(:journey_session) { build(:"#{journey::I18N_NAMESPACE}_session") }

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

    describe "#induction_completed" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}}) }

      context "claim eligibility DOES NOT have a current value" do
        it "returns nil" do
          expect(form.induction_completed).to be_nil
        end
      end

      context "claim eligibility DOES have a current value" do
        let(:current_claim) do
          claims = journey::POLICIES.map { |policy| create(:claim, policy: policy, eligibility_attributes: {induction_completed: false}) }
          CurrentClaim.new(claims: claims)
        end

        it "returns the current value" do
          expect(form.induction_completed).to be false
        end
      end
    end

    describe "#save" do
      context "induction_completed submitted" do
        let(:params) { ActionController::Parameters.new({slug: slug, claim: {induction_completed: true}}) }

        context "claim eligibility didn't have induction_completed" do
          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy: policy) }
            CurrentClaim.new(claims: claims)
          end

          it "updates the induction_completed on claim eligibility" do
            expect(form.save).to be true

            current_claim.claims.each do |claim|
              eligibility = claim.eligibility.reload

              expect(eligibility.induction_completed).to be true
            end
          end
        end

        context "claim eligibility already had a induction_completed" do
          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy: policy, eligibility_attributes: {induction_completed: false}) }
            CurrentClaim.new(claims: claims)
          end

          it "updates the induction_completed on claim eligibility" do
            expect(form.save).to be true

            current_claim.claims.each do |claim|
              eligibility = claim.eligibility.reload

              expect(eligibility.induction_completed).to be true
            end
          end
        end

        context "claim model fails validation unexpectedly" do
          it "raises an error" do
            allow(current_claim).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)

            expect { form.save }.to raise_error(ActiveRecord::RecordInvalid)
          end
        end
      end

      context "induction_completed missing" do
        let(:params) { ActionController::Parameters.new({slug: slug, claim: {induction_completed: ""}}) }

        it "does not save and adds error to form" do
          expect(form.save).to be false
          expect(form.errors[:induction_completed]).to eq ["Select yes if you have completed your induction"]
        end
      end
    end
  end

  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples "induction_completed_form", Journeys::AdditionalPaymentsForTeaching
  end
end
