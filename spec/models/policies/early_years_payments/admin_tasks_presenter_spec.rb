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

  describe "#practitioner_entered_dob" do
    let(:claim) do
      create(
        :claim,
        :submitted,
        policy: Policies::EarlyYearsPayments,
        date_of_birth: Date.new(1990, 1, 1)
      )
    end

    subject { described_class.new(claim).practitioner_entered_dob }

    it { is_expected.to eq I18n.l(Date.new(1990, 1, 1)) }
  end

  describe "#one_login_claimant_dob" do
    let(:claim) do
      create(
        :claim,
        :submitted,
        policy: Policies::EarlyYearsPayments,
        onelogin_idv_date_of_birth: Date.new(1990, 2, 1)
      )
    end

    subject { described_class.new(claim).one_login_claimant_dob }

    it { is_expected.to eq I18n.l(Date.new(1990, 2, 1)) }
  end
end
