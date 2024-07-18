require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::ChemistryCoursesForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session) }
  let(:chemistry_courses) { [""] }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        chemistry_courses:
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
          .for(:chemistry_courses)
          .with_message("Select all the courses you teach otherwise select you do not teach any of these courses")
        )
      end
    end

    context "when non-existent injection option selected" do
      it do
        is_expected.not_to(
          allow_value(["foo"])
          .for(:chemistry_courses)
          .with_message("Select all the courses you teach otherwise select you do not teach any of these courses")
        )
      end
    end
  end

  describe "#save" do
    let(:chemistry_courses) { ["alevel_chemistry", "gcse_chemistry"] }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.chemistry_courses }.to(chemistry_courses)
      )
    end
  end
end