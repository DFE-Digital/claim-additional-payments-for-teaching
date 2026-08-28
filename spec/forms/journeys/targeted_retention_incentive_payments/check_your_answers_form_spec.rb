require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::CheckYourAnswersForm do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments, current_academic_year:)
  end

  let(:current_academic_year) { AcademicYear.new(2026) }
  let(:journey) { Journeys::TargetedRetentionIncentivePayments }
  let(:school) { create(:school) }

  let(:answers) {
    build(
      :targeted_retention_incentive_payments_answers,
      :submittable,
      award_amount: 999
    )
  }

  let(:journey_session) { create(:targeted_retention_incentive_payments_session, answers: answers) }

  subject do
    described_class.new(
      journey_session: journey_session,
      params: ActionController::Parameters.new(
        claim: {
          claimant_declaration: "1"
        }
      ),
      session: {},
      journey:
    )
  end

  describe "#save" do
    around do |example|
      freeze_time(Time.new(2026, 2, 11)) do
        example.run
      end
    end

    it "saves all answers into the claim and eligibility models" do
      subject.save

      claim = subject.claim

      expect(claim.policy).to eql(Policies::TargetedRetentionIncentivePayments)
      expect(claim.read_attribute(:award_amount)).to eql(999)
    end
  end
end
