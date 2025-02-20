require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::EligibleDegreeSubjectForm, type: :model do
  describe "validations" do
    let(:journey_session) do
      create(:targeted_retention_incentive_payments_session)
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
          allow_value(nil).for(:eligible_degree_subject)
          .with_message("Select yes if you have a degree in an eligible subject")
        )
      end
    end

    describe "#save" do
      let(:params) do
        {
          eligible_degree_subject: true
        }
      end

      it "updates the session" do
        expect { form.save }.to(
          change { journey_session.reload.answers.eligible_degree_subject }
          .from(nil).to(true)
        )
      end
    end
  end
end
