require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::CurrentSchoolForm, type: :model do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)
  end

  let(:journey_session) do
    create(:targeted_retention_incentive_payments_session)
  end

  let(:school) do
    create(
      :school,
      :targeted_retention_incentive_payments_eligible,
      targeted_retention_incentive_payments_award_amount: 5_000
    )
  end

  subject(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::TargetedRetentionIncentivePayments,
      params: ActionController::Parameters.new(claim: params)
    )
  end

  describe "#save" do
    context "when invalid" do
      let(:params) do
        {}
      end

      it "doesn't set the award amount" do
        expect do
          expect(form.save).to be false
        end.not_to change { journey_session.reload.answers.award_amount }
      end
    end

    context "when valid" do
      let(:params) do
        {current_school_id: school.id}
      end

      it "sets the award amount" do
        expect { expect(form.save).to be true }.to(
          change { journey_session.reload.answers.award_amount }
          .from(nil).to(5_000)
        )
      end
    end
  end
end
