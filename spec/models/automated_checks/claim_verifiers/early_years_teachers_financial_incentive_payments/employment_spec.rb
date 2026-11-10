require "rails_helper"

RSpec.describe(
  AutomatedChecks::ClaimVerifiers::
    EarlyYearsTeachersFinancialIncentivePayments::Employment
) do
  it "enqueues the employment task job without checking HMRC inline" do
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments
    )
    expect(
      EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob
    ).not_to receive(:perform_now)

    expect {
      described_class.new(claim: claim).perform
    }.to have_enqueued_job(
      Tasks::EarlyYearsTeachersFinancialIncentivePayments::EmploymentJob
    ).with(claim)

    expect(claim.tasks.employment).not_to exist
  end
end
