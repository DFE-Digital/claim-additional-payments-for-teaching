require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::ProviderVerificationV2 do
  subject(:verifier) { described_class.new(claim: claim) }

  let(:academic_year) { AcademicYear.new("2025/2026") }
  let(:verifier_user) { create(:dfe_signin_user) }

  describe "#perform" do
    context "with a Year 2 claim where provider verification passes" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          policy: Policies::FurtherEducationPayments,
          academic_year: academic_year,
          eligibility: create(
            :further_education_payments_eligibility,
            :eligible,
            # Claimant data
            contract_type: "fixed_term",
            teaching_responsibilities: true,
            further_education_teaching_start_year: "2023",
            teaching_hours_per_week: "more_than_12",
            half_teaching_hours: true,
            subject_to_formal_performance_action: false,
            subject_to_disciplinary_action: false,
            # Provider verification data - all matching
            provider_verification_completed_at: 1.day.ago,
            provider_verification_verified_by_id: verifier_user.id,
            provider_verification_contract_type: "fixed_term",
            provider_verification_teaching_responsibilities: true,
            provider_verification_teaching_start_year_matches_claim: true,
            provider_verification_teaching_hours_per_week: "20_or_more_hours_per_week",
            provider_verification_half_teaching_hours: true,
            provider_verification_performance_measures: false,
            provider_verification_disciplinary_action: false,
            provider_verification_taught_at_least_one_academic_term: true,
            provider_verification_teaching_qualification: "yes"
          )
        )
      end

      it "creates a passing task" do
        expect { verifier.perform }.to change { claim.tasks.count }.by(1)

        task = claim.tasks.find_by(name: "fe_provider_verification_v2")
        expect(task).to be_present
        expect(task.passed).to be true
        expect(task.manual).to be false
      end

      it "does not create duplicate tasks" do
        verifier.perform
        expect { verifier.perform }.not_to change { claim.tasks.count }
      end
    end

    context "with a Year 2 claim where provider verification fails" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          policy: Policies::FurtherEducationPayments,
          academic_year: academic_year,
          eligibility: create(
            :further_education_payments_eligibility,
            :eligible,
            # Claimant data
            contract_type: "fixed_term",
            teaching_responsibilities: true,
            further_education_teaching_start_year: "2023",
            teaching_hours_per_week: "more_than_12",
            half_teaching_hours: true,
            subject_to_formal_performance_action: false,
            subject_to_disciplinary_action: false,
            # Provider verification data - teaching responsibilities doesn't match
            provider_verification_completed_at: 1.day.ago,
            provider_verification_verified_by_id: verifier_user.id,
            provider_verification_contract_type: "fixed_term",
            provider_verification_teaching_responsibilities: false, # Mismatch!
            provider_verification_teaching_start_year_matches_claim: true,
            provider_verification_teaching_hours_per_week: "20_or_more_hours_per_week",
            provider_verification_half_teaching_hours: true,
            provider_verification_performance_measures: false,
            provider_verification_disciplinary_action: false,
            provider_verification_taught_at_least_one_academic_term: true,
            provider_verification_teaching_qualification: "yes"
          )
        )
      end

      it "creates a failing task" do
        expect { verifier.perform }.to change { claim.tasks.count }.by(1)

        task = claim.tasks.find_by(name: "fe_provider_verification_v2")
        expect(task).to be_present
        expect(task.passed).to be false
        expect(task.manual).to be false
      end
    end

    context "with teaching hours matching" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          policy: Policies::FurtherEducationPayments,
          academic_year: academic_year,
          eligibility: create(
            :further_education_payments_eligibility,
            :eligible,
            contract_type: "fixed_term",
            teaching_responsibilities: true,
            further_education_teaching_start_year: "2023",
            half_teaching_hours: true,
            subject_to_formal_performance_action: false,
            subject_to_disciplinary_action: false,
            provider_verification_completed_at: 1.day.ago,
            provider_verification_verified_by_id: verifier_user.id,
            provider_verification_contract_type: "fixed_term",
            provider_verification_teaching_responsibilities: true,
            provider_verification_teaching_start_year_matches_claim: true,
            provider_verification_half_teaching_hours: true,
            provider_verification_performance_measures: false,
            provider_verification_disciplinary_action: false,
            provider_verification_taught_at_least_one_academic_term: true,
            provider_verification_teaching_qualification: "yes"
          )
        )
      end

      context "when claimant says more_than_12 and provider says 12_to_20" do
        before do
          claim.eligibility.update!(
            teaching_hours_per_week: "more_than_12",
            provider_verification_teaching_hours_per_week: "12_to_20_hours_per_week"
          )
        end

        it "passes (more_than_12 includes 12-20 range)" do
          verifier.perform
          expect(claim.tasks.find_by(name: "fe_provider_verification_v2").passed).to be true
        end
      end

      context "when claimant says more_than_12 and provider says 20_or_more" do
        before do
          claim.eligibility.update!(
            teaching_hours_per_week: "more_than_12",
            provider_verification_teaching_hours_per_week: "20_or_more_hours_per_week"
          )
        end

        it "passes (more_than_12 includes 20+ range)" do
          verifier.perform
          expect(claim.tasks.find_by(name: "fe_provider_verification_v2").passed).to be true
        end
      end

      context "when claimant says more_than_12 but provider says fewer_than_2_and_a_half" do
        before do
          claim.eligibility.update!(
            teaching_hours_per_week: "more_than_12",
            provider_verification_teaching_hours_per_week: "fewer_than_2_and_a_half_hours_per_week"
          )
        end

        it "fails (mismatch)" do
          verifier.perform
          expect(claim.tasks.find_by(name: "fe_provider_verification_v2").passed).to be false
        end
      end

      context "with an unexpected teaching_hours_per_week value" do
        before do
          claim.eligibility.update!(
            teaching_hours_per_week: "invalid_value",
            provider_verification_teaching_hours_per_week: "20_or_more_hours_per_week"
          )
        end

        it "raises an ArgumentError" do
          expect { verifier.perform }.to raise_error(ArgumentError, /Unexpected teaching_hours_per_week/)
        end
      end
    end

    context "with a Year 1 claim (2024/2025)" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          policy: Policies::FurtherEducationPayments,
          academic_year: AcademicYear.new("2024/2025"),
          eligibility: create(
            :further_education_payments_eligibility,
            :eligible,
            provider_verification_completed_at: 1.day.ago,
            provider_verification_verified_by_id: verifier_user.id
          )
        )
      end

      it "does not create a task (Y1 guard)" do
        expect { verifier.perform }.not_to change { claim.tasks.count }
      end
    end

    context "when provider verification is not completed" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          policy: Policies::FurtherEducationPayments,
          academic_year: academic_year,
          eligibility: create(
            :further_education_payments_eligibility,
            :eligible
            # No provider_verification_completed_at or verified_by_id
          )
        )
      end

      it "does not create a task" do
        expect { verifier.perform }.not_to change { claim.tasks.count }
      end
    end
  end
end
