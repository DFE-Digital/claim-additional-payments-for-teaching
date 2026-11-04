require "rails_helper"

RSpec.describe Journeys::SchoolTargetedRetentionIncentivePayments::CheckYourAnswersForm do
  let(:journey) { Journeys::SchoolTargetedRetentionIncentivePayments }
  let(:journey_session) { create(:school_targeted_retention_incentive_payments_session, :with_employment_proof, answers:) }
  let(:answers) do
    build(:school_targeted_retention_incentive_payments_answers,
      national_insurance_number: "AB123456C",
      payroll_gender: "female",
      address_line_1: "1 Test Street",
      address_line_3: "London",
      postcode: "SW1A 1AA",
      banking_name: "John Doe",
      bank_sort_code: "123456",
      bank_account_number: "12345678",
      teacher_auth_email: "test@example.com",
      teacher_auth_verified_name: "John Doe")
  end

  let(:params) do
    ActionController::Parameters.new(
      claim: {claimant_declaration: "1"}
    )
  end

  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)
  end

  subject do
    described_class.new(
      journey:,
      journey_session:,
      session: {},
      params:
    )
  end

  describe "#save" do
    it "enqueues malware scan job" do
      expect {
        subject.save
      }.to have_enqueued_job(BlobMalwareScanResultJob)
        .with(journey_session.answers.confirmed_employment_proof_blob_ids.first)
    end
  end
end
