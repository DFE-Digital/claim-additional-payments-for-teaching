require "rails_helper"

RSpec.describe DataRetention::PoliciesJob do
  before do
    FeatureFlag.enable!(:apply_data_retention_policy)
  end

  context "when the policy is EarlyYearsTeachersFinancialIncentivePayments" do
    it "removes expired employment proof attachments" do
      claim = nil
      blob = nil

      travel_to(Time.zone.local(2025, 9, 1, 12)) do
        claim = create(
          :claim,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          academic_year: AcademicYear.new(2025),
          submitted_at: Time.current,
          eligibility_attributes: {confirmed_employment_proof_blob_ids: []}
        )
        create(:decision, :rejected, claim: claim)
        claim.eligibility.employment_proofs.attach(
          io: StringIO.new("employment proof"),
          filename: "employment-proof.pdf",
          content_type: "application/pdf"
        )
        blob = claim.eligibility.employment_proofs.blobs.first
        claim.eligibility.update!(confirmed_employment_proof_blob_ids: [blob.id])
      end

      travel_to(Time.zone.local(2026, 9, 1, 12)) do
        perform_enqueued_jobs { described_class.perform_now }
      end

      expect(claim.reload.eligibility.confirmed_employment_proof_blob_ids).to be_nil
      expect(claim.eligibility.employment_proofs).not_to be_attached
      expect { blob.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
