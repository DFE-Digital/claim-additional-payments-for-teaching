require "rails_helper"

RSpec.describe(
  Tasks::EarlyYearsTeachersFinancialIncentivePayments::EmploymentJob
) do
  it "fetches HMRC employment before evaluating the claim" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)

    nursery = create(
      :eligible_eytfi_provider,
      name: "Oak Tree Nursery",
      postcode: "SW1A 1AA"
    )

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
      employments: [
        {
          employer: {
            name: nursery.name,
            address: {
              postcode: nursery.postcode
            }
          }
        }
      ]
    }.to_json

    client = instance_double(Hmrc::Employments::Client)

    allow(Hmrc::Employments).to receive(:client).and_return(client)

    expect(client).to receive(:employment_history_for_individual).and_return(
      double(status: 200, body: response_body)
    )

    expect(claim.eligibility.hmrc_employment_check_attempts).to eq(0)

    task = described_class.perform_now(claim)

    expect(claim.eligibility.reload.hmrc_employment_check_attempts).to eq(1)
    expect(task).to be_persisted
    expect(task.passed).to eq(true)
    expect(task.manual).to eq(false)
    expect(claim.eligibility.reload.hmrc_response_body).to eq(response_body)
  end

  it "passes a PAYE match without employer name or address details" do
    nursery = create(
      :eligible_eytfi_provider,
      paye_reference: "123/AB456"
    )

    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {eligible_eytfi_provider_urn: nursery.urn}
    )

    expect(
      ::EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob
    ).to receive(:perform_now).with(claim) do
      claim.eligibility.update!(
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [{employer: {payeReference: "123/AB456"}}]
        }.to_json
      )
    end

    task = described_class.perform_now(claim)

    expect(task).to be_persisted
    expect(task.passed).to be(true)
    expect(task.manual).to be(false)
  end

  it "leaves an ineligible PAYE group for manual checking" do
    nursery = create(
      :eligible_eytfi_provider, paye_reference: "123/AB456",
      registered_person_name: "Oak Group", multiple_nurseries: true
    )

    create(
      :eligible_eytfi_provider, file_upload: nursery.file_upload,
      registered_person_name: "Oak Group", eligible: false
    )

    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {eligible_eytfi_provider_urn: nursery.urn}
    )

    expect(
      ::EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob
    ).to receive(:perform_now).with(claim) do
      claim.eligibility.update!(
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [{
            employer: {
              payeReference: "123/AB456",
              name: nursery.name,
              address: {postcode: nursery.postcode}
            }
          }]
        }.to_json
      )
    end

    task = described_class.perform_now(claim)

    expect(task.passed).to be_nil
    expect(task.manual).to be(true)
    expect(task.reason).to eq("incomplete")
  end

  it "leaves a claimant not found by HMRC for manual checking" do
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments
    )

    expect(
      ::EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob
    ).to receive(:perform_now).with(claim) do
      claim.eligibility.update!(
        hmrc_response_status: 404,
        hmrc_response_body: "not found"
      )
    end

    task = described_class.perform_now(claim)

    expect(task.passed).to be_nil
    expect(task.manual).to eq(true)
    expect(task.reason).to eq("incomplete")
    expect(task.data).to include(
      "check" => nil,
      "passed" => false,
      "failure_reason" => "no_matching_employment"
    )
  end

  it "does not run the job again when an employment task already exists" do
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments
    )

    create(:task, claim: claim, name: "employment")

    expect(
      ::EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob
    ).not_to receive(:perform_now)

    expect { described_class.perform_now(claim) }.not_to(
      change { claim.tasks.count }
    )
    expect(claim.eligibility.reload.hmrc_employment_check_attempts).to eq(0)
  end
  it "persists and increments the count for each failed API attempt" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {hmrc_employment_check_attempts: 1}
    )
    hmrc_job = EarlyYearsTeachersFinancialIncentivePayments::
      HmrcEmploymentCheckJob
    allow(hmrc_job).to receive(:perform_now).with(claim)
      .and_raise(Timeout::Error)

    expect { described_class.perform_now(claim) }.to raise_error(Timeout::Error)
    expect(claim.eligibility.reload.hmrc_employment_check_attempts).to eq(2)

    expect { described_class.perform_now(claim) }.to raise_error(Timeout::Error)
    expect(claim.eligibility.reload.hmrc_employment_check_attempts).to eq(3)
    expect(claim.tasks.employment).not_to exist
  end

  it "does not count a cached HMRC response as another API attempt" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        hmrc_response_status: 200,
        hmrc_response_body: {employments: []}.to_json,
        hmrc_employment_check_attempts: 2
      }
    )

    described_class.perform_now(claim)

    expect(claim.eligibility.reload.hmrc_employment_check_attempts).to eq(2)
  end

  it "does not count an attempt when HMRC integration is disabled" do
    FeatureFlag.disable!(:eytrp_hmrc_integration)
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments
    )

    described_class.perform_now(claim)

    expect(claim.eligibility.reload.hmrc_employment_check_attempts).to eq(0)
  end
end
