require "rails_helper"

RSpec.describe Policies::EarlyYearsPayments::AdminTasksPresenter do
  describe "#employment" do
    let(:claim) do
      create(:claim,
        :submitted,
        policy: Policies::EarlyYearsPayments,
        eligibility_attributes: {
          nursery_urn: eligible_ey_provider.urn,
          start_date: Date.new(2018, 1, 1)
        })
    end

    let(:local_authority) { create(:local_authority, name: "Some LA") }

    let(:eligible_ey_provider) do
      create(
        :eligible_ey_provider,
        nursery_name: "Some Nursery",
        urn: "EY123456",
        local_authority: local_authority
      )
    end

    subject { described_class.new(claim).employment }

    it "shows current employment" do
      expect(subject[0]).to eq(
        ["Current employment", "Some Nursery (EY123456) - Some LA"]
      )
    end

    it "shows start date" do
      expect(subject[1][1]).to eq "1 January 2018"
    end
  end
end
