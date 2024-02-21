require "rails_helper"

RSpec.describe Policies::EarlyCareerPayments::SchoolCheckEmailDataExportPresenter, type: :model do
  subject(:presenter) { described_class.new(claim) }

  let(:claim) { build(:claim) }

  describe "#subject" do
    it { expect(presenter.subject).to eq("") }
  end
end
