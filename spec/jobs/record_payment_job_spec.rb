require "rails_helper"
require "geckoboard"

RSpec.describe RecordPaymentJob do
  let(:claim) { build(:claim) }
  let(:payment) { build(:payment, :with_figures, updated_at: DateTime.now, claims: [claim]) }

  subject { described_class.new }

  it "sends the claim reference, policy and payment date to claims.paid.ENV dataset" do
    ClimateControl.modify ENVIRONMENT_NAME: "environment_name" do
      claim_data = {
        reference: claim.reference,
        policy: claim.policy.to_s,
        performed_at: payment.updated_at.strftime("%Y-%m-%dT%H:%M:%S%:z"),
      }

      dataset_post_stub = stub_geckoboard_dataset_update("claims.paid.environment_name")

      subject.perform(payment)

      expect(dataset_post_stub.with(body: {data: [claim_data]})).to have_been_requested
    end
  end
end
