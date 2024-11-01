require "rails_helper"

RSpec.describe Policies::EarlyYearsPayments::AdminTasksPresenter do
  describe "#employment" do
    let(:claim) {
      create(:claim,
        :submitted,
        policy: Policies::EarlyYearsPayments,
        eligibility_attributes: {
          nursery_urn: eligible_ey_provider.urn,
          start_date: Date.new(2018, 1, 1)
        })
    }
    let(:eligible_ey_provider) { create(:eligible_ey_provider) }

    subject { described_class.new(claim).employment }

    it "shows current employment" do
      expect(subject[0][1]).to eq claim.eligibility.eligible_ey_provider.nursery_name
    end

    it "shows start date" do
      expect(subject[1][1]).to eq "1 January 2018"
    end
  end
end
