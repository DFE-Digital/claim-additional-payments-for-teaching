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
      let(:params) { ActionController::Parameters.new({slug:, claim: { nonsense_id: 1 }}) }

      it "raises an error" do
        expect { form }.to raise_error ActionController::UnpermittedParameters
      end
    end

    describe "#employed_as_supply_teacher" do
      context "new form" do
        let(:params) { ActionController::Parameters.new({ slug:, claim: {} }) }

        it "returns nil" do
          expect(form.employed_as_supply_teacher).to be_nil
        end
      end
    end
  end

  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples "supply_teacher_form", Journeys::AdditionalPaymentsForTeaching
  end
end
