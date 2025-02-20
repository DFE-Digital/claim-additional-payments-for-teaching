require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::TeachingSubjectNowForm, type: :model do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments_only)
  end

  let(:journey_session) do
    create(
      :targeted_retention_incentive_payments_session,
      answers: {}
    )
  end

  let(:params) do
    {}
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::TargetedRetentionIncentivePayments,
      params: ActionController::Parameters.new(claim: params)
    )
  end

  describe "validations" do
    subject { form }

    it do
      is_expected.not_to(
        allow_value(nil).for(:teaching_subject_now).with_message(
          "Select yes if you spend at least half of your contracted hours " \
          "teaching eligible subjects"
        )
      )
    end
  end

  describe "#save" do
    context "when invalid" do
      it "returns false and does not save the journey session" do
        expect { expect(form.save).to be(false) }.to(
          not_change { journey_session.reload.answers.attributes }
        )
      end
    end

    context "when valid" do
      let(:params) do
        {
          teaching_subject_now: "true"
        }
      end

      it "updates the session" do
        expect { expect(form.save).to be(true) }.to(
          change { journey_session.reload.answers.teaching_subject_now }
          .from(nil).to(true)
        )
      end
    end

    context "when valid with false value" do
      let(:params) do
        {
          teaching_subject_now: "false"
        }
      end

      it "updates the session" do
        expect { expect(form.save).to be(true) }.to(
          change { journey_session.reload.answers.teaching_subject_now }
          .from(nil).to(false)
        )
      end
    end
  end
end
