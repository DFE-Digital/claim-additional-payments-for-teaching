require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::TeachingQualificationForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:answers_hash) { {} }
  let(:teaching_qualification) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        teaching_qualification:
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
      let(:teaching_qualification) { nil }

      it do
        is_expected.not_to(
          allow_value(nil)
          .for(:teaching_qualification)
          .with_message("Select if you have a teaching qualification")
        )
      end
    end

    context "when non-existent injection option selected" do
      let(:teaching_qualification) { "foo" }

      it do
        is_expected.not_to(
          allow_value("foo")
          .for(:teaching_qualification)
          .with_message("Select if you have a teaching qualification")
        )
      end
    end
  end

  describe "#save" do
    let(:teaching_qualification) { "yes" }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.teaching_qualification }.to("yes")
      )
    end
  end
end
