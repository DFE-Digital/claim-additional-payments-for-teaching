require "rails_helper"

RSpec.describe DeletePersonalDataFromOldClaimsJob do
  describe "#perform" do
    let(:current_academic_year) { AcademicYear.current }
    let(:last_academic_year) { Time.zone.local(current_academic_year.start_year, 8, 1) }

    Policies::POLICIES.each do |policy|
      it "deletes the personal data from eligible #{policy} claims" do
        submitted_claim = create(:claim, :submitted, policy: policy)
        rejected_claim = create(:claim, :submitted, policy: policy)
        create(:decision, :rejected, claim: rejected_claim, created_at: last_academic_year)
        paid_claim = create(:claim, :approved, policy: policy)
        create(:payment, :confirmed, :with_figures, claims: [paid_claim], scheduled_payment_date: last_academic_year)

        DeletePersonalDataFromOldClaimsJob.new.perform

        expect(Claim.find(submitted_claim.id).personal_data_removed_at).to be_nil
        expect(Claim.find(rejected_claim.id).personal_data_removed_at).to_not be_nil
        expect(Claim.find(paid_claim.id).personal_data_removed_at).to_not be_nil
      end
    end
  end
end
