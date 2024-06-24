require "rails_helper"

RSpec.describe Policies::InternationalRelocationPayments::AdminTasksPresenter, type: :model do
  subject { presenter }

  let(:claim) { build(:claim, policy: Policies::InternationalRelocationPayments) }
  let(:eligibility) { claim.eligibility }
  let(:presenter) { described_class.new(claim) }

  it { is_expected.to delegate_method(:eligibility).to(:claim) }

  describe "#identity_confirmation" do
    subject { presenter.identity_confirmation }

    it "returns an array of label and values for displaying information for the identity confirmation check" do
      is_expected.to eq [["Current school", nil], ["Contact number", nil]]
    end
  end

  describe "#qualifications" do
    subject(:qualifications) { presenter.qualifications }

    it "returns an array of label and values for displaying information for the qualifications check" do
      is_expected.to eq [["Qualifications", "No qualifications"]]
    end
  end
end
