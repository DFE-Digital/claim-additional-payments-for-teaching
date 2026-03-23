require "rails_helper"

RSpec.describe Policies::DuplicateFinder do
  describe "#find_approved_claims_in_same_academic_year" do
    let(:claim_attributes) { {policy:} }
    let(:payroll_run) { create(:payroll_run) }

    let(:approved_claim) do
      claim = create(:claim, :approved, **claim_attributes)
      create(:payment, claims: [claim], payroll_run:)

      claim
    end

    let(:submitted_claim) { create(:claim, :submitted, **claim_attributes) }

    # Only approved claims are considered, so this should be ignored
    let(:other_submitted_claim) { create(:claim, :submitted, **claim_attributes) }

    let(:other_policy_approved_claims) do
      other_policies = Policies.all.reject { |p| p == policy }

      other_policies.map do |other_policy|
        claim = create(:claim, :approved, **claim_attributes.merge(policy: other_policy))
        create(:payment, claims: [claim], payroll_run:)

        claim
      end
    end

    subject do
      policy::DuplicateFinder
        .new(submitted_claim)
        .find_approved_claims_in_same_academic_year
    end

    Policies.all.each do |policy|
      context "for #{policy}" do
        let(:policy) { policy }

        before do
          approved_claim
          other_policy_approved_claims
          other_submitted_claim
        end

        context "same email_address" do
          let(:claim_attributes) do
            super().merge(email_address: "same-email@example.com")
          end

          it "returns the already approved claim for this policy" do
            is_expected.to contain_exactly(approved_claim)
          end
        end

        context "same national_insurance_number" do
          let(:claim_attributes) do
            super().merge(national_insurance_number: "JH123456D")
          end

          it "returns the already approved claim for this policy" do
            is_expected.to contain_exactly(approved_claim)
          end
        end

        context "same bank details" do
          let(:claim_attributes) do
            super().merge(bank_account_number: "12345678", bank_sort_code: "000000")
          end

          it "returns the already approved claim for this policy" do
            is_expected.to contain_exactly(approved_claim)
          end
        end

        context "same name and dob" do
          let(:claim_attributes) do
            super().merge(first_name: "John", surname: "Smith", date_of_birth: Date.new(1980, 1, 1))
          end

          it "returns the already approved claim for this policy" do
            is_expected.to contain_exactly(approved_claim)
          end
        end
      end
    end

    # Only these policies have TRN in their ELIGIBILITY_MATCHING_ATTRIBUTES
    [
      Policies::EarlyCareerPayments,
      Policies::FurtherEducationPayments,
      Policies::StudentLoans,
      Policies::TargetedRetentionIncentivePayments
    ].each do |policy|
      context "for #{policy}" do
        let(:policy) { policy }

        before do
          approved_claim
          other_policy_approved_claims
          other_submitted_claim
        end

        context "same TRN" do
          let(:claim_attributes) do
            super().merge(eligibility_attributes: {teacher_reference_number: "7654321"})
          end

          it "returns the already approved claim for this policy" do
            is_expected.to contain_exactly(approved_claim)
          end
        end
      end
    end

    # Only IRP has passport_number in their ELIGIBILITY_MATCHING_ATTRIBUTES
    context "for Policies::InternationalRelocationPayments" do
      let(:policy) { Policies::InternationalRelocationPayments }

      before do
        approved_claim
        other_submitted_claim
      end

      context "same TRN" do
        let(:claim_attributes) do
          super().merge(eligibility_attributes: {passport_number: "7654321"})
        end

        it "returns the already approved claim for this policy" do
          is_expected.to contain_exactly(approved_claim)
        end
      end
    end
  end
end
