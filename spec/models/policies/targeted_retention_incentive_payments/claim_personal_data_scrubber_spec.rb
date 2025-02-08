require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::ClaimPersonalDataScrubber do
  it_behaves_like(
    "a claim personal data scrubber",
    Policies::TargetedRetentionIncentivePayments
  )

  subject(:personal_data_scrubber) { described_class.new.scrub_completed_claims }
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments) }
  let(:current_academic_year) { AcademicYear.current }
  let(:last_academic_year) { Time.zone.local(current_academic_year.start_year, 8, 1) }
  let(:user) { create(:dfe_signin_user) }

  it "does not delete details from a claim that has a payment, but has a payrollable topup" do
    eligibility = create(:targeted_retention_incentive_payments_eligibility, :eligible, award_amount: 1500.0)

    claim = create(:claim, :approved, policy: Policies::TargetedRetentionIncentivePayments, eligibility: eligibility)

    create(:payment, :confirmed, :with_figures, claims: [claim], scheduled_payment_date: last_academic_year)
    create(:topup, payment: nil, claim: claim, award_amount: 500, created_by: user)

    expect { personal_data_scrubber }.not_to change { claim.reload.attributes }
  end

  it "does not delete details from a claim that has a payment, but has a payrolled topup without payment confirmation" do
    claim = nil

    travel_to 2.months.ago do
      eligibility = create(:targeted_retention_incentive_payments_eligibility, :eligible, award_amount: 1500.0)
      claim = create(:claim, :approved, policy: Policies::TargetedRetentionIncentivePayments, eligibility: eligibility)
      create(:payment, :confirmed, :with_figures, claims: [claim], scheduled_payment_date: last_academic_year)
    end

    payment2 = create(:payment, :with_figures, claims: [claim], scheduled_payment_date: nil)
    create(:topup, payment: payment2, claim: claim, award_amount: 500, created_by: user)

    expect { personal_data_scrubber }.not_to change { claim.reload.attributes }
  end
end
