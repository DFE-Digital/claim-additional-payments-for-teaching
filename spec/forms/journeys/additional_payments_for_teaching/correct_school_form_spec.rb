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

    let(:journey) { Journeys::AdditionalPaymentsForTeaching }
    let(:journey_session) { create(:additional_payments_session) }
    let(:params) { ActionController::Parameters.new }
    let(:form) { described_class.new(journey:, journey_session:, params:) }
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
        expect { save }.to change { journey_session.reload.answers.current_school_id }.to(school.id)
      end

      it "resets the somewhere_else attribute" do
        expect { save }.to change { journey_session.reload.answers.school_somewhere_else }.to eq(false)
      end

      it "writes to the journey session" do
        expect { save }.to change { journey_session.answers.current_school_id }.to(school.id)
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
        journey_session.answers.assign_attributes(
          current_school_id: school.id,
          school_somewhere_else: false
        )
        journey_session.save!
      end

      it "resets the school association" do
        expect { save }.to change { journey_session.reload.answers.current_school_id }.to(nil)
      end

      it "resets the somewhere_else attribute" do
        expect { save }.to change { journey_session.reload.answers.school_somewhere_else }.to eq(true)
      end
    end
  end
end
