require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::SubjectsTaughtForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:answers_hash) { {} }
  let(:subjects_taught) { [] }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        subjects_taught:
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
      let(:subjects_taught) { [] }

      it do
        is_expected.not_to(
          allow_value([])
          .for(:subjects_taught)
          .with_message("Select the subject areas that you teach, or select ‘I do not teach any of these subjects’")
        )
      end
    end

    context "when non-existent injection option selected" do
      let(:subjects_taught) { ["foo"] }

      it do
        is_expected.not_to(
          allow_value(["foo"])
          .for(:subjects_taught)
          .with_message("Select the subject areas that you teach, or select ‘I do not teach any of these subjects’")
        )
      end
    end
  end

  describe "#save" do
    let(:subjects_taught) { ["chemistry", "maths"] }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.subjects_taught }.to(["chemistry", "maths"])
      )
    end

    context "when changing some answers" do
      let(:answers_hash) do
        {
          subjects_taught: %w[maths physics],
          maths_courses: %w[approved_level_321_maths],
          physics_courses: %w[alevel_physics]
        }
      end

      let(:subjects_taught) { %w[chemistry maths] }

      it "resets dependent answers" do
        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.subjects_taught }.to(subjects_taught)
          .and(change { journey_session.reload.answers.physics_courses }.to([])
          .and(not_change { journey_session.reload.answers.maths_courses }))
        )
      end
    end

    context "when changing all answers" do
      let(:answers_hash) do
        {
          subjects_taught: %w[
            building_construction
            chemistry
            computing
            early_years
            engineering_manufacturing
            maths
            physics
          ],
          building_construction_courses: %w[none],
          chemistry_courses: %w[none],
          computing_courses: %w[none],
          early_years_courses: %w[none],
          engineering_manufacturing_courses: %w[none],
          maths_courses: %w[none],
          physics_courses: %w[none]
        }
      end

      let(:subjects_taught) { %w[none] }

      it "resets dependent answers" do
        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.subjects_taught }.to(subjects_taught)
          .and(change { journey_session.reload.answers.building_construction_courses }.to([])
          .and(change { journey_session.reload.answers.chemistry_courses }.to([])
          .and(change { journey_session.reload.answers.computing_courses }.to([])
          .and(change { journey_session.reload.answers.early_years_courses }.to([])
          .and(change { journey_session.reload.answers.engineering_manufacturing_courses }.to([])
          .and(change { journey_session.reload.answers.maths_courses }.to([])
          .and(change { journey_session.reload.answers.physics_courses }.to([]))))))))
        )
      end
    end
  end

  describe "#clear_answers_from_session" do
    let(:answers_hash) do
      { subjects_taught: %w[maths physics] }
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.subjects_taught }.from(%w[maths physics]).to([])
    end
  end
end
