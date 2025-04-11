require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::EntireTermContractForm, type: :model do
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
        allow_value(nil).for(:has_entire_term_contract).with_message(
          "Select yes if you have a contract to teach at the same school for " \
          "an entire term or longer"
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
          has_entire_term_contract: true
        }
      end

      it "saves the journey session" do
        expect { expect(form.save).to be(true) }.to(
          change { journey_session.reload.answers.has_entire_term_contract }
          .from(nil).to(true)
        )
      end
    end
  end
end
