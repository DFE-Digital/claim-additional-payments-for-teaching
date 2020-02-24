require "rails_helper"

RSpec.describe Claim::PiiScrubber, type: :model do
  let(:over_two_months_ago) { 2.months.ago - 1.day }

  it "does not delete details from a submitted claim" do
    claim = create(:claim, :submitted, updated_at: over_two_months_ago)

    expect { Claim::PiiScrubber.new.scrub_completed_claims }.not_to change { claim.reload.attributes }
  end

  it "does not delete details from an approved but unpaid claim" do
    claim = create(:claim, :approved, updated_at: over_two_months_ago)

    expect { Claim::PiiScrubber.new.scrub_completed_claims }.not_to change { claim.reload.attributes }
  end

  it "does not delete details from a newly rejected claim" do
    claim = create(:claim, :rejected)

    expect { Claim::PiiScrubber.new.scrub_completed_claims }.not_to change { claim.reload.attributes }
  end

  it "does not delete details from a newly paid claim" do
    claim = create(:claim, :approved)
    create(:payment, :with_figures, claims: [claim])

    expect { Claim::PiiScrubber.new.scrub_completed_claims }.not_to change { claim.reload.attributes }
  end

  it "deletes expected details from an old rejected claim, setting a pii_removed_at timestamp" do
    freeze_time do
      claim = create(:claim, :submitted)
      create(:decision, :rejected, claim: claim, created_at: over_two_months_ago)

      Claim::PiiScrubber.new.scrub_completed_claims
      cleaned_claim = Claim.find(claim.id)

      expect(cleaned_claim.first_name).to be_nil
      expect(cleaned_claim.middle_name).to be_nil
      expect(cleaned_claim.surname).to be_nil
      expect(cleaned_claim.date_of_birth).to be_nil
      expect(cleaned_claim.address_line_1).to be_nil
      expect(cleaned_claim.address_line_2).to be_nil
      expect(cleaned_claim.address_line_3).to be_nil
      expect(cleaned_claim.address_line_4).to be_nil
      expect(cleaned_claim.postcode).to be_nil
      expect(cleaned_claim.payroll_gender).to be_nil
      expect(cleaned_claim.national_insurance_number).to be_nil
      expect(cleaned_claim.bank_sort_code).to be_nil
      expect(cleaned_claim.bank_account_number).to be_nil
      expect(cleaned_claim.building_society_roll_number).to be_nil
      expect(cleaned_claim.pii_removed_at).to eq(Time.zone.now)
    end
  end

  it "deletes expected details from an old paid claim, setting a pii_removed_at timestamp" do
    freeze_time do
      claim = create(:claim, :approved)
      create(:payment, :with_figures, claims: [claim], scheduled_payment_date: over_two_months_ago)

      Claim::PiiScrubber.new.scrub_completed_claims
      cleaned_claim = Claim.find(claim.id)

      expect(cleaned_claim.first_name).to be_nil
      expect(cleaned_claim.middle_name).to be_nil
      expect(cleaned_claim.surname).to be_nil
      expect(cleaned_claim.date_of_birth).to be_nil
      expect(cleaned_claim.address_line_1).to be_nil
      expect(cleaned_claim.address_line_2).to be_nil
      expect(cleaned_claim.address_line_3).to be_nil
      expect(cleaned_claim.address_line_4).to be_nil
      expect(cleaned_claim.postcode).to be_nil
      expect(cleaned_claim.payroll_gender).to be_nil
      expect(cleaned_claim.national_insurance_number).to be_nil
      expect(cleaned_claim.bank_sort_code).to be_nil
      expect(cleaned_claim.bank_account_number).to be_nil
      expect(cleaned_claim.building_society_roll_number).to be_nil
      expect(cleaned_claim.pii_removed_at).to eq(Time.zone.now)
    end
  end

  it "calculates the date past which claims are considered old at runtime" do
    # Initialise the scrubber, and create a claim
    scrubber = Claim::PiiScrubber.new
    claim = create(:claim, :submitted)
    create(:decision, :rejected, claim: claim)

    # Travel three months forwards. At this point the claim should be considered
    # old enough to scrub information from.
    travel_to(3.months.from_now)
    scrubber.scrub_completed_claims
    cleaned_claim = Claim.find(claim.id)
    expect(cleaned_claim.pii_removed_at).to eq(Time.zone.now)
  end
end
