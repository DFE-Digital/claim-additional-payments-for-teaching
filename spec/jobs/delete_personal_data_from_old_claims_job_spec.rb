require "rails_helper"

RSpec.describe DeletePersonalDataFromOldClaimsJob do
  describe "#perform" do
    let(:current_academic_year) { AcademicYear.current }
    let(:last_academic_year) { Time.zone.local(current_academic_year.start_year, 8, 1) }
    let(:over_1_ago) { 12.months.ago - 2.days }

    Policies::POLICIES.each do |policy|
      it "deletes the personal data from eligible #{policy} claims" do
        # EY is not based on AY windows
        rejection_or_payment_datetime = policy.is_a?(Policies::EarlyYearsPayments) ? over_1_ago : last_academic_year

        submitted_claim = create(:claim, :submitted, policy: policy)
        rejected_claim = create(:claim, :submitted, policy: policy)
        create(:decision, :rejected, claim: rejected_claim, created_at: rejection_or_payment_datetime)
        paid_claim = create(:claim, :approved, policy: policy)
        create(:payment, :confirmed, :with_figures, claims: [paid_claim], scheduled_payment_date: rejection_or_payment_datetime)

        DeletePersonalDataFromOldClaimsJob.new.perform

        expect(Claim.find(submitted_claim.id).personal_data_removed_at).to be_nil
        expect(Claim.find(rejected_claim.id).personal_data_removed_at).to_not be_nil
        expect(Claim.find(paid_claim.id).personal_data_removed_at).to_not be_nil
      end
    end
  end
end
