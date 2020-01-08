require "rails_helper"
require "geckoboard"

RSpec.describe RecordPaymentJob do
  let(:claims) { build_list(:claim, 2, :submitted) }
  let(:payment) { build(:payment, :with_figures, updated_at: DateTime.now, claims: claims) }

  subject { described_class.new }

  it "sends each claim’s reference, policy and payment date to claims.paid.ENV dataset" do
    ClimateControl.modify ENVIRONMENT_NAME: "environment_name" do
      dataset_post_stub = stub_geckoboard_dataset_update("claims.paid.environment_name")

      subject.perform(payment)

      claims.each do |claim|
        claim_data = {
          reference: claim.reference,
          policy: claim.policy.to_s,
          performed_at: payment.updated_at.strftime("%Y-%m-%dT%H:%M:%S%:z"),
        }
        expect(dataset_post_stub.with(body: {data: [claim_data]})).to have_been_requested
      end
    end
  end
end
