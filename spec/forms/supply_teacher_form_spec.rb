require "rails_helper"

RSpec.describe SupplyTeacherForm do
  shared_examples "supply_teacher_form" do |journey|
    before {
      create(:journey_configuration, :student_loans)
      create(:journey_configuration, :additional_payments)
    }

    let(:current_claim) do
      claims = journey::POLICIES.map { |policy| create(:claim, policy:) }
      CurrentClaim.new(claims:)
    end

    let(:slug) { "supply-teacher" }

    subject(:form) { described_class.new(claim: current_claim, journey:, params:) }

    context "unpermitted claim param" do
      let(:params) { ActionController::Parameters.new({ slug:, claim: { random_param: 1 } }) }

      it "raises an error" do
        expect { form }.to raise_error ActionController::UnpermittedParameters
      end
    end

    describe "#save" do
      context "employed_as_supply_teacher missing" do
        let(:params) { ActionController::Parameters.new({ slug:, claim: { employed_as_supply_teacher: "Yes" } }) }

        context "claim eligibility didn't have employed_as_supply_teacher" do
          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy:) }
            CurrentClaim.new(claims:)
          end

          it "saves employed_as_supply_teacher on claim eligibility" do
            expect(form.save).to be true

            current_claim.claims.each do |claim|
              eligibility = claim.eligibility.reload

              expect(eligibility.employed_as_supply_teacher).to be_truthy
            end
          end
        end

        context "claim eligibility already had a employed_as_supply_teacher" do
          let(:current_claim) do
            claims = journey::POLICIES.map do |policy|
              create(:claim, policy:, eligibility_attributes: { employed_as_supply_teacher: false })
            end
            CurrentClaim.new(claims:)
          end

          it "updates employed_as_supply_teacher on claim eligibility" do
            expect(form.save).to be true

            current_claim.claims.each do |claim|
              eligibility = claim.eligibility.reload

              expect(eligibility.employed_as_supply_teacher).to be_truthy
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

      context "employed_as_supply_teacher missing" do
        let(:params) { ActionController::Parameters.new({ slug:, claim: { employed_as_supply_teacher: nil } }) }

        it "does not save and adds error to form" do
          expect(form.save).to be false
          expect(form.errors[:employed_as_supply_teacher]).to eq ["Select yes if you are a supply teacher"]
        end
      end
    end
  end

  # TODO: is it applicable for another journey? if not, unwrap shared examples
  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples "supply_teacher_form", Journeys::AdditionalPaymentsForTeaching
  end
end