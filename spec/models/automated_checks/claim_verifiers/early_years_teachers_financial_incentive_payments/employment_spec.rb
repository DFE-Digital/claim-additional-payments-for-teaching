require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::EarlyYearsTeachersFinancialIncentivePayments::Employment do
  it "fetches HMRC employment inline before evaluating the claim" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)
    nursery = create(:eligible_eytfi_provider, name: "Oak Tree Nursery", postcode: "SW1A 1AA")
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        eligible_eytfi_provider_urn: nursery.urn,
        teacher_auth_verified_name: "John Doe",
        teacher_auth_verified_date_of_birth: "1970-12-13"
      }
    )
    response_body = {
      employments: [{employer: {name: nursery.name, address: {postcode: nursery.postcode}}}]
    }.to_json
    client = instance_double(Hmrc::Employments::Client)
    allow(Hmrc::Employments).to receive(:client).and_return(client)
    expect(client).to receive(:employment_history_for_individual).and_return(
      double(status: 200, body: response_body)
    )

    task = described_class.new(claim: claim).perform

    expect(task).to be_persisted
    expect(task.passed).to eq(true)
    expect(task.manual).to eq(false)
    expect(claim.eligibility.reload.hmrc_response_body).to eq(response_body)
  end

  it "passes automatically when the employer PAYE reference matches without name or address details" do
    nursery = create(:eligible_eytfi_provider, paye_reference: "123/AB456")
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {eligible_eytfi_provider_urn: nursery.urn}
    )
    expect(::EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob)
      .to receive(:perform_now).with(claim) do
        claim.eligibility.update!(
          hmrc_response_status: 200,
          hmrc_response_body: {
            employments: [{employer: {payeReference: "123/AB456"}}]
          }.to_json
        )
      end

    task = described_class.new(claim: claim).perform

    expect(task).to be_persisted
    expect(task.passed).to be(true)
    expect(task.manual).to be(false)
  end

  it "leaves employment for manual checking when HMRC cannot find the claimant" do
    claim = create(:claim, policy: Policies::EarlyYearsTeachersFinancialIncentivePayments)
    expect(::EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob)
      .to receive(:perform_now).with(claim) do
        claim.eligibility.update!(hmrc_response_status: 404, hmrc_response_body: "not found")
      end

    task = described_class.new(claim: claim).perform

    expect(task.passed).to be_nil
    expect(task.manual).to eq(true)
    expect(task.reason).to eq("incomplete")
  end

  it "does not run the job again when an employment task already exists" do
    claim = create(:claim, policy: Policies::EarlyYearsTeachersFinancialIncentivePayments)
    create(:task, claim: claim, name: "employment")
    expect(::EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob)
      .not_to receive(:perform_now)

    expect { described_class.new(claim: claim).perform }.not_to change { claim.tasks.count }
  end
end
