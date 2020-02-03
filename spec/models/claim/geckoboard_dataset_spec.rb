require "rails_helper"

RSpec.describe Claim::GeckoboardDataset, type: :model do
  let(:claim) { build(:claim, :submitted, created_at: DateTime.now) }
  let(:dataset) { Claim::GeckoboardDataset.new }

  it "returns an award_amount of nil for a claim with no eligibility" do
    ClimateControl.modify ENVIRONMENT_NAME: "test" do
      data = dataset.data_for_claims([claim])
      expect(data.first["award_amount"]).to be_nil
    end
  end

  it "correctly converts award amounts to an integer of pennies" do
    ClimateControl.modify ENVIRONMENT_NAME: "test" do
      eligible_claim = build(
        :claim,
        :submitted,
        student_loan_plan: :plan_1,
        eligibility: build(:student_loans_eligibility, student_loan_repayment_amount: 2345.67),
      )
      data = dataset.data_for_claims([eligible_claim])
      expect(data.first[:award_amount]).to eq(234567)
    end
  end

  it "sends a claim's details to the Geckoboard dataset" do
    ClimateControl.modify ENVIRONMENT_NAME: "test" do
      event = Claim::GeckoboardDataset.new(claims: [claim])

      dataset_post_stub = stub_geckoboard_dataset_update("claims.test")

      event.save

      expect(dataset_post_stub.with { |request|
        request_body_matches_geckoboard_data_for_claims?(request, [claim])
      }).to have_been_requested
    end
  end

  context "with lots of claims" do
    let(:claims) { build_list(:claim, 520, :submitted, created_at: DateTime.now) }

    it "batches the claims into groups" do
      event = Claim::GeckoboardDataset.new(claims: claims)

      dataset_post_stub = stub_geckoboard_dataset_update("claims.test")

      event.save

      expect(dataset_post_stub.with { |request|
        request_body_matches_geckoboard_data_for_claims?(request, claims.first(500))
      }).to have_been_requested

      expect(dataset_post_stub.with { |request|
        request_body_matches_geckoboard_data_for_claims?(request, claims.last(20))
      }).to have_been_requested
    end
  end

  describe "#delete" do
    it "deletes the dataset" do
      dataset_delete_stub = stub_geckoboard_dataset_delete("claims.test")

      dataset = Claim::GeckoboardDataset.new
      dataset.delete

      expect(dataset_delete_stub).to have_been_requested
    end
  end
end
