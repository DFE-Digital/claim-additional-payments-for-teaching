require "rails_helper"

RSpec.describe ResetClaimForm, type: :model do
  describe "#save" do
    subject { described_class.new(journey:, params:, journey_session:).save }

    let(:journey) { Journeys::TeacherStudentLoanReimbursement }
    let(:params) { nil }
    let(:journey_session) { build(:"#{journey::I18N_NAMESPACE}_session") }

    it { is_expected.to be_truthy }
  end
end
