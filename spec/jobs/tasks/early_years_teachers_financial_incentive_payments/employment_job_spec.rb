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
    FeatureFlag.enable!(:eytrp_hmrc_integration)

    nursery = create(
      :eligible_eytfi_provider,
      paye_references: ["123/AB456"]
    )

    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {eligible_eytfi_provider_urn: nursery.urn}
    )

    claim.eligibility.update!(
      teacher_auth_verified_name: "John Doe",
      teacher_auth_verified_date_of_birth: "1970-12-13"
    )
    attributes = {
      hmrc_response_status: 200,
      hmrc_response_body: {
        employments: [{employer: {payeReference: "123/AB456"}}]
      }.to_json
    }
    client = instance_double(Hmrc::Employments::Client)
    allow(Hmrc::Employments).to receive(:client).and_return(client)
    expect(client).to receive(:employment_history_for_individual).and_return(
      double(
        status: attributes.fetch(:hmrc_response_status),
        body: attributes.fetch(:hmrc_response_body)
      )
    )

    task = described_class.perform_now(claim)

    expect(task).to be_persisted
    expect(task.passed).to be(true)
    expect(task.manual).to be(false)
  end

  it "leaves an ineligible PAYE group for manual checking" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)

    nursery = create(
      :eligible_eytfi_provider, paye_references: ["123/AB456"],
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

    claim.eligibility.update!(
      teacher_auth_verified_name: "John Doe",
      teacher_auth_verified_date_of_birth: "1970-12-13"
    )
    attributes = {
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
    }
    client = instance_double(Hmrc::Employments::Client)
    allow(Hmrc::Employments).to receive(:client).and_return(client)
    expect(client).to receive(:employment_history_for_individual).and_return(
      double(
        status: attributes.fetch(:hmrc_response_status),
        body: attributes.fetch(:hmrc_response_body)
      )
    )

    task = described_class.perform_now(claim)

    expect(task.passed).to be_nil
    expect(task.manual).to be(true)
    expect(task.reason).to eq("incomplete")
  end

  it "leaves a claimant not found by HMRC for manual checking" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)

    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments
    )

    claim.eligibility.update!(
      teacher_auth_verified_name: "John Doe",
      teacher_auth_verified_date_of_birth: "1970-12-13"
    )
    attributes = {
      hmrc_response_status: 404,
      hmrc_response_body: "not found"
    }
    client = instance_double(Hmrc::Employments::Client)
    allow(Hmrc::Employments).to receive(:client).and_return(client)
    expect(client).to receive(:employment_history_for_individual).and_return(
      double(
        status: attributes.fetch(:hmrc_response_status),
        body: attributes.fetch(:hmrc_response_body)
      )
    )

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

    expect(Hmrc::Employments).not_to receive(:client)

    expect { described_class.perform_now(claim) }.not_to(
      change { claim.tasks.count }
    )
    expect(claim.eligibility.reload.hmrc_employment_check_attempts).to eq(0)
  end

  it "counts each API attempt even when it raises" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        hmrc_employment_check_attempts: 1,
        teacher_auth_verified_name: "John Doe",
        teacher_auth_verified_date_of_birth: "1970-12-13"
      }
    )
    client = instance_double(Hmrc::Employments::Client)
    allow(Hmrc::Employments).to receive(:client).and_return(client)
    allow(client).to receive(:employment_history_for_individual)
      .and_raise(Timeout::Error)

    expect { described_class.perform_now(claim) }.to raise_error(Timeout::Error)
    expect(claim.eligibility.reload.hmrc_employment_check_attempts).to eq(2)

    expect { described_class.perform_now(claim) }.to raise_error(Timeout::Error)
    expect(claim.eligibility.reload.hmrc_employment_check_attempts).to eq(3)
    expect(claim.tasks.employment).not_to exist
  end

  it "fetches again if a response exists without an employment task" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        teacher_auth_verified_name: "John Doe",
        teacher_auth_verified_date_of_birth: "1970-12-13",
        hmrc_response_status: 200,
        hmrc_response_body: {employments: []}.to_json,
        hmrc_employment_check_attempts: 2
      }
    )
    client = instance_double(Hmrc::Employments::Client)
    allow(Hmrc::Employments).to receive(:client).and_return(client)
    expect(client).to receive(:employment_history_for_individual).and_return(
      double(status: 404, body: "not found")
    )

    described_class.perform_now(claim)

    expect(claim.eligibility.reload.hmrc_employment_check_attempts).to eq(3)
    expect(claim.eligibility.hmrc_response_status).to eq(404)
    expect(claim.tasks.employment).to exist
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

  it "retries a rate-limited response after one minute without saving a task" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        teacher_auth_verified_name: "John Doe",
        teacher_auth_verified_date_of_birth: "1970-12-13"
      }
    )
    client = instance_double(Hmrc::Employments::Client)
    allow(Hmrc::Employments).to receive(:client).and_return(client)
    expect(client).to receive(:employment_history_for_individual).and_return(
      double(status: 429, body: "rate limited")
    )

    freeze_time do
      expect {
        described_class.perform_now(claim)
      }.to have_enqueued_job(described_class).with(claim)
        .at(1.minute.from_now)
    end

    eligibility = claim.eligibility.reload
    expect(eligibility.hmrc_employment_check_attempts).to eq(1)
    expect(eligibility.hmrc_response_status).to be_nil
    expect(eligibility.hmrc_response_body).to be_nil
    expect(eligibility.employment_check_date_range_start).to be_nil
    expect(eligibility.employment_check_date_range_end).to be_nil
    expect(claim.tasks.employment).not_to exist
  end

  it "waits four minutes after the fourth unsuccessful attempt" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        teacher_auth_verified_name: "John Doe",
        teacher_auth_verified_date_of_birth: "1970-12-13",
        hmrc_employment_check_attempts: 3
      }
    )
    client = instance_double(Hmrc::Employments::Client)
    allow(Hmrc::Employments).to receive(:client).and_return(client)
    expect(client).to receive(:employment_history_for_individual).and_return(
      double(status: 500, body: "server error")
    )

    freeze_time do
      expect {
        described_class.perform_now(claim)
      }.to have_enqueued_job(described_class).with(claim)
        .at(4.minutes.from_now)
    end

    expect(claim.eligibility.reload.hmrc_employment_check_attempts).to eq(4)
    expect(claim.eligibility.hmrc_response_status).to be_nil
    expect(claim.eligibility.hmrc_response_body).to be_nil
    expect(claim.tasks.employment).not_to exist
  end

  it "saves the fifth unsuccessful response and creates a manual task" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        teacher_auth_verified_name: "John Doe",
        teacher_auth_verified_date_of_birth: "1970-12-13",
        hmrc_employment_check_attempts: 4
      }
    )
    client = instance_double(Hmrc::Employments::Client)
    allow(Hmrc::Employments).to receive(:client).and_return(client)
    expect(client).to receive(:employment_history_for_individual).and_return(
      double(status: 429, body: "final rate-limit response")
    )

    expect { described_class.perform_now(claim) }
      .not_to have_enqueued_job(described_class)

    eligibility = claim.eligibility.reload
    expect(eligibility.hmrc_employment_check_attempts).to eq(5)
    expect(eligibility.hmrc_response_status).to eq(429)
    expect(eligibility.hmrc_response_body).to eq("final rate-limit response")
    expect(eligibility.employment_check_date_range_start).to eq(
      2.months.ago.to_date
    )
    expect(eligibility.employment_check_date_range_end).to eq(Date.current)
    expect(claim.tasks.employment.sole).to have_attributes(
      passed: nil, manual: true, reason: "incomplete"
    )
  end

  it "creates a passing task if a subsequent attempt succeeds" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)
    nursery = create(:eligible_eytfi_provider, paye_references: ["123/AB456"])
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        eligible_eytfi_provider_urn: nursery.urn,
        teacher_auth_verified_name: "John Doe",
        teacher_auth_verified_date_of_birth: "1970-12-13"
      }
    )
    client = instance_double(Hmrc::Employments::Client)
    allow(Hmrc::Employments).to receive(:client).and_return(client)
    body = {employments: [{employer: {payeReference: "123/AB456"}}]}.to_json
    expect(client).to receive(:employment_history_for_individual).and_return(
      double(status: 429, body: "rate limited"),
      double(status: 200, body: body)
    )

    described_class.perform_now(claim)
    clear_enqueued_jobs

    expect { described_class.perform_now(claim.reload) }
      .not_to have_enqueued_job(described_class)

    expect(claim.eligibility.reload.hmrc_employment_check_attempts).to eq(2)
    expect(claim.eligibility.hmrc_response_status).to eq(200)
    expect(claim.eligibility.hmrc_response_body).to eq(body)
    expect(claim.tasks.employment.sole).to have_attributes(
      passed: true, manual: false
    )
  end

  it "does not retry a 404 response" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        teacher_auth_verified_name: "John Doe",
        teacher_auth_verified_date_of_birth: "1970-12-13"
      }
    )
    client = instance_double(Hmrc::Employments::Client)
    allow(Hmrc::Employments).to receive(:client).and_return(client)
    expect(client).to receive(:employment_history_for_individual).and_return(
      double(status: 404, body: "not found")
    )

    expect { described_class.perform_now(claim) }
      .not_to have_enqueued_job(described_class)

    expect(claim.eligibility.reload.hmrc_employment_check_attempts).to eq(1)
    expect(claim.eligibility.hmrc_response_status).to eq(404)
    expect(claim.tasks.employment.sole).to have_attributes(
      passed: nil, manual: true
    )
  end

  it "does not save a retry response when the next attempt raises" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        teacher_auth_verified_name: "John Doe",
        teacher_auth_verified_date_of_birth: "1970-12-13"
      }
    )
    client = instance_double(Hmrc::Employments::Client)
    allow(Hmrc::Employments).to receive(:client).and_return(client)
    expect(client).to receive(:employment_history_for_individual)
      .ordered.and_return(double(status: 429, body: "rate limited"))
    expect(client).to receive(:employment_history_for_individual)
      .ordered.and_raise(Timeout::Error)

    described_class.perform_now(claim)

    expect {
      described_class.perform_now(claim.reload)
    }.to raise_error(Timeout::Error)

    eligibility = claim.eligibility.reload
    expect(eligibility.hmrc_employment_check_attempts).to eq(2)
    expect(eligibility.hmrc_response_status).to be_nil
    expect(eligibility.hmrc_response_body).to be_nil
    expect(claim.tasks.employment).not_to exist
  end

  it "looks back two calendar months across a year boundary" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        teacher_auth_verified_name: "John Doe",
        teacher_auth_verified_date_of_birth: "1970-12-13"
      }
    )
    client = instance_double(Hmrc::Employments::Client)
    allow(Hmrc::Employments).to receive(:client).and_return(client)
    expect(client).to receive(:employment_history_for_individual)
      .with(hash_including(from_date: Date.new(2025, 11, 15)))
      .and_return(double(status: 200, body: {employments: []}.to_json))

    travel_to Time.zone.local(2026, 1, 15, 12) do
      described_class.perform_now(claim)
    end

    expect(claim.eligibility.reload.employment_check_date_range_start)
      .to eq(Date.new(2025, 11, 15))
    expect(claim.eligibility.employment_check_date_range_end)
      .to eq(Date.new(2026, 1, 15))
  end

  it "uses the last available day when the lookback month is shorter" do
    FeatureFlag.enable!(:eytrp_hmrc_integration)
    claim = create(
      :claim,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        teacher_auth_verified_name: "John Doe",
        teacher_auth_verified_date_of_birth: "1970-12-13"
      }
    )
    client = instance_double(Hmrc::Employments::Client)
    allow(Hmrc::Employments).to receive(:client).and_return(client)
    expect(client).to receive(:employment_history_for_individual)
      .with(hash_including(from_date: Date.new(2026, 2, 28)))
      .and_return(double(status: 200, body: {employments: []}.to_json))

    travel_to Time.zone.local(2026, 4, 30, 12) do
      described_class.perform_now(claim)
    end

    expect(claim.eligibility.reload.employment_check_date_range_start)
      .to eq(Date.new(2026, 2, 28))
  end
end
