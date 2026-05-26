require "rails_helper"

RSpec.describe Journeys::EarlyYearsTeachersFinancialIncentivePayments::CheckYourAnswersForm do
  let(:journey) { Journeys::EarlyYearsTeachersFinancialIncentivePayments }
  let(:journey_session) { create(:eytfi_session, :with_employment_proof, answers:) }
  let(:nursery) { create(:eligible_eytfi_provider) }

  let(:answers) do
    build(:eytfi_answers,
      nursery_id: nursery.id,
      claimant_declaration: true,
      teaching_qualification_confirmation: true,
      has_eligible_qualification: true,
      national_insurance_number: "AB123456C",
      payroll_gender: "female",
      address_line_1: "1 Test Street",
      address_line_3: "London",
      postcode: "SW1A 1AA",
      banking_name: "John Doe",
      bank_sort_code: "123456",
      bank_account_number: "12345678",
      teacher_auth_email: "test@example.com",
      teacher_auth_verified_name: "John Doe",
      email_verified: true,
      provide_mobile_number: false,
      mobile_verified: false)
  end

  let(:params) do
    ActionController::Parameters.new(
      claim: {claimant_declaration: "1"}
    )
  end

  subject(:form) do
    described_class.new(
      journey:,
      journey_session:,
      session: {},
      params:
    )
  end

  before do
    create(:journey_configuration, :early_years_teachers_financial_incentive_payments)
    allow_any_instance_of(Journeys::EarlyYearsTeachersFinancialIncentivePayments::EligibilityChecker)
      .to receive(:ineligible?).and_return(false)
    allow(Journeys::EarlyYearsTeachersFinancialIncentivePayments::AnswersStudentLoansDetailsUpdater)
      .to receive(:call)
  end

  describe "#save" do
    it "attaches employment proofs to the eligibility" do
      form.save
      expect(form.claim.eligibility.employment_proofs).to be_attached
    end

    it "copies confirmed_employment_proof_blob_ids to the eligibility" do
      form.save
      expect(form.claim.eligibility.confirmed_employment_proof_blob_ids).to eq(
        journey_session.answers.confirmed_employment_proof_blob_ids
      )
    end

    it "enqueues a malware scan job for each confirmed blob" do
      expect {
        form.save
      }.to have_enqueued_job(EarlyYearsTeachersFinancialIncentivePayments::FetchEmploymentProofMalwareScanResultJob)
        .with(journey_session.answers.confirmed_employment_proof_blob_ids.first)
    end
  end
end
