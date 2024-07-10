require "rails_helper"

RSpec.describe Policies::InternationalRelocationPayments::AdminTasksPresenter, type: :model do
  subject { presenter }

  let(:claim) { build(:claim, policy: Policies::InternationalRelocationPayments) }
  let(:eligibility) { claim.eligibility }
  let(:presenter) { described_class.new(claim) }

  describe "#claim" do
    subject { presenter.claim }

    it { is_expected.to eq claim }
  end
end
