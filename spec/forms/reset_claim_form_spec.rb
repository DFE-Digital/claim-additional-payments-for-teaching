require "rails_helper"

RSpec.describe ResetClaimForm, type: :model do
  describe "#save" do
    subject { described_class.new(claim:, journey:, params:).save }

    let(:claim) { double }
    let(:journey) { double }
    let(:params) { nil }

    it { is_expected.to be_truthy }
  end
end
