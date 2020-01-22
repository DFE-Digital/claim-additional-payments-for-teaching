require "rails_helper"

RSpec.describe Geckoboard::UpdateUncheckedClaimsJob do
  describe "#perform" do
    before do
      @dataset_post_stub = stub_geckoboard_dataset_update
    end

    it "updates the Geckoboard claim dataset with all unchecked claims" do
      claims_awaiting_checking = create_list(:claim, 2, :submitted)
      create(:claim, :approved)
      create(:claim, :submittable)

      Geckoboard::UpdateUncheckedClaimsJob.new.perform

      expect(@dataset_post_stub.with { |request|
        request_body_matches_geckoboard_data_for_claims?(request, claims_awaiting_checking)
      }).to have_been_requested
    end
  end
end
