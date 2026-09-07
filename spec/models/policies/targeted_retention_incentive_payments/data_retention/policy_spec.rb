require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::DataRetention::Policy do
  describe ".claims_to_scrub" do
    it "doesn't return unscrubbed claims from the current academic year" do
      create(
        :claim,
        policy: Policies::TargetedRetentionIncentivePayments,
        academic_year: AcademicYear.current,
        email_address: "test@example.com"
      )

      expect(described_class.claims_to_scrub).to be_empty
    end

    it "doesn't return scrubbed claims" do
      claim = create(
        :claim,
        policy: Policies::TargetedRetentionIncentivePayments,
        academic_year: AcademicYear.previous
      )

      empty_attrs = described_class.claim_redacted_attributes.to_h do |attr|
        [attr, nil]
      end

      claim.assign_attributes(empty_attrs)

      empty_attrs = described_class.eligibility_redacted_attributes.to_h do |attr|
        [attr, nil]
      end

      claim.eligibility.assign_attributes(empty_attrs)

      claim.eligibility.save!
      claim.save!

      expect(described_class.claims_to_scrub).to be_empty
    end

    it "doesn't return claims for other policies" do
      create(
        :claim,
        policy: Policies::StudentLoans,
        academic_year: AcademicYear.previous,
        email_address: "test@example.com"
      )

      expect(described_class.claims_to_scrub).to be_empty
    end

    it "returns claims where no attributes have been scrubbed" do
      claim = create(
        :claim,
        policy: Policies::TargetedRetentionIncentivePayments,
        academic_year: AcademicYear.previous,
        email_address: "test@example.com"
      )

      expect(described_class.claims_to_scrub).to match_array([claim])
    end

    # Note for TRI all eligibility attributes are retained
    it "returns claims where only some attributes have been scrubbed" do
      redacted_attributes = described_class
        .claim_attributes
        .transform_values { DateTime.now }
        .excluding(:building_society_roll_number)

      claim = create(
        :claim,
        policy: Policies::TargetedRetentionIncentivePayments,
        academic_year: AcademicYear.previous,
        email_address: "test@example.com",
        redacted_attributes: redacted_attributes
      )

      expect(described_class.claims_to_scrub).to match_array([claim])
    end
  end
end
