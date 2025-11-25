require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::EligibleFeProvider do
  describe "#claims" do
    it "only returns claims belonging to the provider" do
      provider_1 = create(:eligible_fe_provider, :with_school)

      provider_2 = create(:eligible_fe_provider, :with_school)

      eligibility_1 = create(
        :further_education_payments_eligibility,
        school: provider_1.school
      )

      eligibility_2 = create(
        :further_education_payments_eligibility,
        school: provider_2.school
      )

      claim_1 = create(:claim, :further_education, eligibility: eligibility_1)

      claim_2 = create(:claim, :further_education, eligibility: eligibility_2)

      expect(provider_1.claims).to contain_exactly(claim_1)

      expect(provider_2.claims).to contain_exactly(claim_2)
    end
  end

  describe "claim_scopes" do
    describe ".unverified" do
      it "returns only unverified claims belonging to the provider" do
        provider_1 = create(:eligible_fe_provider, :with_school)

        provider_2 = create(:eligible_fe_provider, :with_school)

        _unverified_eligibility_failed_applicant_check = create(
          :further_education_payments_eligibility,
          school: provider_1.school,
          repeat_applicant_check_passed: false,
          claim: create(:claim, :further_education)
        )

        _verified_eligibility = create(
          :further_education_payments_eligibility,
          :provider_verification_completed,
          school: provider_1.school,
          repeat_applicant_check_passed: false,
          claim: create(:claim, :further_education)
        )

        _unverified_eligibility_other_provider = create(
          :further_education_payments_eligibility,
          school: provider_2.school,
          repeat_applicant_check_passed: true,
          claim: create(:claim, :further_education)
        )

        unverified_eligibility = create(
          :further_education_payments_eligibility,
          school: provider_1.school,
          repeat_applicant_check_passed: true,
          claim: create(:claim, :further_education)
        )

        expect(provider_1.claims.unverified).to contain_exactly(
          unverified_eligibility.claim
        )
      end
    end

    describe ".verified" do
      it "returns only verified claims belonging to the provider" do
        provider_1 = create(:eligible_fe_provider, :with_school)

        provider_2 = create(:eligible_fe_provider, :with_school)

        _unverified_eligibility = create(
          :further_education_payments_eligibility,
          school: provider_1.school,
          claim: create(:claim, :further_education)
        )

        _verified_eligibility_other_provider = create(
          :further_education_payments_eligibility,
          :provider_verification_completed,
          school: provider_2.school,
          claim: create(:claim, :further_education)
        )

        verified_eligibility = create(
          :further_education_payments_eligibility,
          :provider_verification_completed,
          school: provider_1.school,
          claim: create(:claim, :further_education)
        )

        expect(provider_1.claims.verified).to contain_exactly(
          verified_eligibility.claim
        )
      end
    end

    describe ".verification_overdue" do
      it "returns only overdue claims belonging to the provider" do
        provider_1 = create(:eligible_fe_provider, :with_school)

        provider_2 = create(:eligible_fe_provider, :with_school)

        _not_overdue_eligibility = create(
          :further_education_payments_eligibility,
          school: provider_1.school,
          claim: create(:claim, :further_education, created_at: 1.week.ago)
        )

        _overdue_eligibility_other_provider = create(
          :further_education_payments_eligibility,
          school: provider_2.school,
          claim: create(:claim, :further_education, created_at: 3.weeks.ago)
        )

        overdue_eligibility = create(
          :further_education_payments_eligibility,
          school: provider_1.school,
          claim: create(:claim, :further_education, created_at: 3.weeks.ago)
        )

        expect(provider_1.claims.verification_overdue).to contain_exactly(
          overdue_eligibility.claim
        )
      end
    end

    describe ".verification_not_started" do
      it "returns only claims with verification not started belonging to the provider" do
        provider_1 = create(:eligible_fe_provider, :with_school)

        provider_2 = create(:eligible_fe_provider, :with_school)

        _verification_in_progress_eligibility = create(
          :further_education_payments_eligibility,
          :provider_verification_started,
          school: provider_1.school,
          claim: create(:claim, :further_education)
        )

        _not_started_other_provider = create(
          :further_education_payments_eligibility,
          school: provider_2.school,
          claim: create(:claim, :further_education)
        )

        not_started_eligibility = create(
          :further_education_payments_eligibility,
          school: provider_1.school,
          claim: create(:claim, :further_education)
        )

        expect(provider_1.claims.verification_not_started).to contain_exactly(
          not_started_eligibility.claim
        )
      end
    end

    describe ".verification_in_progress" do
      it "returns only claims with verification in progress belonging to the provider" do
        provider_1 = create(:eligible_fe_provider, :with_school)

        provider_2 = create(:eligible_fe_provider, :with_school)

        _not_started_eligibility = create(
          :further_education_payments_eligibility,
          school: provider_1.school,
          claim: create(:claim, :further_education)
        )

        _in_progress_other_provider = create(
          :further_education_payments_eligibility,
          :provider_verification_started,
          school: provider_2.school,
          claim: create(:claim, :further_education)
        )

        in_progress_eligibility = create(
          :further_education_payments_eligibility,
          :provider_verification_started,
          school: provider_1.school,
          claim: create(:claim, :further_education)
        )

        expect(provider_1.claims.verification_in_progress).to contain_exactly(
          in_progress_eligibility.claim
        )
      end
    end
  end
end
