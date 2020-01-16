require "rails_helper"
require "geckoboard"

RSpec.describe RecordPaymentJob do
  let(:payroll_run) do
    create(:payroll_run, :confirmation_report_uploaded,
      claims_counts: {StudentLoans => 2, MathsAndPhysics => 3})
  end

  subject { described_class.new }

  it "sends each claim’s reference, policy and payment date to claims.paid.ENV dataset" do
    ClimateControl.modify ENVIRONMENT_NAME: "environment_name" do
      claim_data = payroll_run.claims.map { |claim|
        {
          reference: claim.reference,
          policy: claim.policy.to_s,
          performed_at: claim.scheduled_payment_date.strftime("%Y-%m-%dT%H:%M:%S%:z"),
        }
      }

      dataset_post_stub = stub_geckoboard_dataset_update("claims.paid.environment_name")

      subject.perform(payroll_run.claims.pluck(:id))

      expect(dataset_post_stub.with(body: {data: claim_data})).to have_been_requested
    end
  end
end
