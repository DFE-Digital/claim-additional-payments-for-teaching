require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::CorrectSchoolForm, type: :model do
  before do
    create(
      :journey_configuration,
      :additional_payments,
      current_academic_year: AcademicYear.new(2023)
    )
  end

  describe "#save" do
    subject(:save) { form.save }

    let(:claim) { CurrentClaim.new(claims: [create(:claim, policy: Policies::LevellingUpPremiumPayments)]) }
    let(:journey) { Journeys::AdditionalPaymentsForTeaching }
    let(:journey_session) do
      build(:journeys_session, journey: journey::ROUTING_NAME)
    end
    let(:params) { ActionController::Parameters.new }
    let(:form) { described_class.new(claim:, journey:, journey_session:, params:) }
    let!(:school) { create(:school, :eligible_for_journey, journey:) }

    context "when choosing a school" do
      let(:params) do
        ActionController::Parameters.new({
          claim: {
            current_school_id: school.id
          }
        })
      end

      it "updates the claim with the correct school attributes" do
        expect { save }.to change { claim.reload.eligibility.current_school_id }.to(school.id)
      end

      it "resets the somewhere_else attribute" do
        expect { save }.to change { claim.reload.eligibility.school_somewhere_else }.to eq(false)
      end
    end

    context "with an existing school association and wants to change school" do
      let(:params) do
        ActionController::Parameters.new({
          claim: {
            current_school_id: nil
          }
        })
      end

      before do
        claim.eligibility.update!(current_school_id: school.id, school_somewhere_else: false)
      end

      it "resets the school association" do
        expect { save }.to change { claim.reload.eligibility.current_school_id }.to(nil)
      end

      it "resets the somewhere_else attribute" do
        expect { save }.to change { claim.reload.eligibility.school_somewhere_else }.to eq(true)
      end
    end
  end
end
