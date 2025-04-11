require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::EmployedDirectlyForm, type: :model do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments_only)
  end

  let(:params) do
    {}
  end

  let(:journey_session) do
    create(:targeted_retention_incentive_payments_session)
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
        allow_value(nil).for(:employed_directly).with_message(
          "Select yes if you are directly employed by your school"
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
          employed_directly: true
        }
      end

      it "saves the journey session" do
        expect { expect(form.save).to be(true) }.to(
          change { journey_session.reload.answers.employed_directly }
          .from(nil).to(true)
        )
      end
    end
  end
end
