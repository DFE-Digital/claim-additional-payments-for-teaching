require "rails_helper"

RSpec.describe ResetClaimForm, type: :model do
  describe "#save" do
    subject { described_class.new(claim:, journey:, params:, journey_session:).save }

    let(:claim) { double }
    let(:journey) { Journeys::TeacherStudentLoanReimbursement }
    let(:params) { nil }
    let(:journey_session) do
      build(:journeys_session, journey: journey::ROUTING_NAME)
    end

    it { is_expected.to be_truthy }
  end
end
