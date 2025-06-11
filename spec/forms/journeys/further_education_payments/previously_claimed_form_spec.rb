require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::PreviouslyClaimedForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:answers_hash) { {} }
  let(:previously_claimed) { "" }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        previously_claimed:
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
      it "is not valid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:previously_claimed]).to eql(["Choose yes if you previously received a Targeted Retention Incentive payment for work in further education"])
      end
    end
  end

  describe "#save" do
    let(:previously_claimed) { false }

    it "updates journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.previously_claimed }.to(false)
      )
    end
  end
end
