require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::BuildingConstructionCoursesForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session) }
  let(:building_construction_courses) { [""] }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        building_construction_courses:
      }
    )
  end

  subject do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  describe "validations" do
    context "when no option selected" do
      it do
        is_expected.not_to(
          allow_value([""])
          .for(:building_construction_courses)
          .with_message("Select the courses that you teach, or select ‘I do not teach any of these courses’")
        )
      end
    end

    context "when non-existent injection option selected" do
      it do
        is_expected.not_to(
          allow_value(["foo"])
          .for(:building_construction_courses)
          .with_message("Select the courses that you teach, or select ‘I do not teach any of these courses’")
        )
      end
    end
  end

  describe "#save" do
    let(:building_construction_courses) { ["level3_buildingconstruction_approved", "tlevel_building"] }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.building_construction_courses }.to(building_construction_courses)
      )
    end
  end
end
