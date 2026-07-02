require "rails_helper"

RSpec.describe Admin::TaskListForm do
  describe "#claims" do
    context "when status filters are not applied" do
      it "returns ClaimPresenters for each claim" do
        claim_1 = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )

        create(
          :task,
          :passed,
          name: "ey_eoi_cross_reference",
          claim: claim_1
        )

        create(
          :task,
          :failed,
          name: "employment",
          claim: claim_1
        )

        claim_2 = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )

        create(
          :task,
          :failed,
          name: "ey_eoi_cross_reference",
          claim: claim_2
        )

        create(
          :task,
          :passed,
          name: "employment",
          claim: claim_2
        )

        form = described_class.new(policy_name: "early_years_payments")

        expect(form.claims.map(&:reference)).to contain_exactly(
          claim_1.reference,
          claim_2.reference
        )

        claim_1_presenter = form.claims.find { |c| c.reference == claim_1.reference }

        claim_2_presenter = form.claims.find { |c| c.reference == claim_2.reference }

        expect(claim_1_presenter.task("ey_eoi_cross_reference").status).to eq("passed")
        expect(claim_1_presenter.task("one_login_identity").status).to eq("incomplete")
        expect(claim_1_presenter.task("ey_alternative_verification").status).to eq("not_applicable")
        expect(claim_1_presenter.task("employment").status).to eq("failed")
        expect(claim_1_presenter.task("student_loan_plan").status).to eq("incomplete")
        expect(claim_1_presenter.task("payroll_details").status).to eq("incomplete")
        expect(claim_1_presenter.task("payroll_gender").status).to eq("incomplete")

        expect(claim_2_presenter.task("ey_eoi_cross_reference").status).to eq("failed")
        expect(claim_2_presenter.task("one_login_identity").status).to eq("incomplete")
        expect(claim_2_presenter.task("ey_alternative_verification").status).to eq("not_applicable")
        expect(claim_2_presenter.task("employment").status).to eq("passed")
        expect(claim_2_presenter.task("student_loan_plan").status).to eq("incomplete")
        expect(claim_2_presenter.task("payroll_details").status).to eq("incomplete")
        expect(claim_2_presenter.task("payroll_gender").status).to eq("incomplete")
      end
    end

    context "when status filters are applied" do
      it "returns ClaimPresenters matching the filters" do
        claim_1 = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )

        create(
          :task,
          :passed,
          name: "ey_eoi_cross_reference",
          claim: claim_1
        )

        create(
          :task,
          :failed,
          name: "employment",
          claim: claim_1
        )

        claim_2 = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )

        create(
          :task,
          :failed,
          name: "ey_eoi_cross_reference",
          claim: claim_2
        )

        create(
          :task,
          :passed,
          name: "employment",
          claim: claim_2
        )

        form = described_class.new(
          policy_name: "early_years_payments",
          statuses: {"employment" => ["failed"]}
        )

        expect(form.claims.map(&:reference)).to contain_exactly(
          claim_1.reference
        )
      end
    end

    context "when multiple filters are applied" do
      context "when the filters are for the same task" do
        it "ors the filters" do
          claim_1 = create(
            :claim,
            policy: Policies::EarlyYearsPayments,
            academic_year: AcademicYear.current
          )

          create(
            :task,
            :passed,
            name: "ey_eoi_cross_reference",
            claim: claim_1
          )

          claim_2 = create(
            :claim,
            policy: Policies::EarlyYearsPayments,
            academic_year: AcademicYear.current
          )

          create(
            :task,
            :failed,
            name: "ey_eoi_cross_reference",
            claim: claim_2
          )

          form = described_class.new(
            policy_name: "early_years_payments",
            statuses: {"ey_eoi_cross_reference" => ["passed", "failed"]}
          )

          expect(form.claims.map(&:reference)).to contain_exactly(
            claim_1.reference,
            claim_2.reference
          )
        end
      end

      context "when the filters are for different tasks" do
        it "ands the filters" do
          claim_1 = create(
            :claim,
            policy: Policies::EarlyYearsPayments,
            academic_year: AcademicYear.current
          )

          create(
            :task,
            :passed,
            name: "ey_eoi_cross_reference",
            claim: claim_1
          )

          create(
            :task,
            :failed,
            name: "employment",
            claim: claim_1
          )

          claim_2 = create(
            :claim,
            policy: Policies::EarlyYearsPayments,
            academic_year: AcademicYear.current
          )

          create(
            :task,
            :failed,
            name: "ey_eoi_cross_reference",
            claim: claim_2
          )

          create(
            :task,
            :passed,
            name: "employment",
            claim: claim_2
          )

          form = described_class.new(
            policy_name: "early_years_payments",
            statuses: {
              "ey_eoi_cross_reference" => ["passed", "failed"],
              "employment" => ["failed"]
            }
          )

          expect(form.claims.map(&:reference)).to contain_exactly(
            claim_1.reference
          )
        end
      end
    end

    context "when filtering by employment match statuses" do
      it "filters claims by no_match employment status" do
        claim_with_no_match = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )

        create(
          :task, :claim_verifier_context,
          name: "employment",
          claim: claim_with_no_match,
          passed: nil,
          claim_verifier_match: :none,
          manual: false,
          created_by: nil
        )

        claim_with_no_data = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )

        create(
          :task, :claim_verifier_context,
          name: "employment",
          claim: claim_with_no_data,
          passed: nil,
          claim_verifier_match: nil,
          manual: false,
          created_by: nil
        )

        claim_with_match = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )

        create(
          :task,
          name: "employment",
          claim: claim_with_match,
          passed: true,
          claim_verifier_match: :all,
          manual: false
        )

        form = described_class.new(
          policy_name: "early_years_payments",
          statuses: {"employment" => ["no_match"]}
        )

        expect(form.claims.map(&:reference)).to contain_exactly(
          claim_with_no_match.reference
        )
      end

      it "filters claims by no_data employment status" do
        claim_with_no_match = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )

        create(
          :task, :claim_verifier_context,
          name: "employment",
          claim: claim_with_no_match,
          passed: nil,
          claim_verifier_match: :none,
          manual: false,
          created_by: nil
        )

        claim_with_no_data = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )

        create(
          :task, :claim_verifier_context,
          name: "employment",
          claim: claim_with_no_data,
          passed: nil,
          claim_verifier_match: nil,
          manual: false,
          created_by: nil
        )

        claim_with_match = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )

        create(
          :task,
          name: "employment",
          claim: claim_with_match,
          passed: true,
          claim_verifier_match: :all,
          manual: false
        )

        form = described_class.new(
          policy_name: "early_years_payments",
          statuses: {"employment" => ["no_data"]}
        )

        expect(form.claims.map(&:reference)).to contain_exactly(
          claim_with_no_data.reference
        )
      end

      it "filters claims by passed employment status" do
        claim_with_no_match = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )

        create(
          :task, :claim_verifier_context,
          name: "employment",
          claim: claim_with_no_match,
          passed: nil,
          claim_verifier_match: :none,
          manual: false,
          created_by: nil
        )

        claim_with_match = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )

        create(
          :task,
          name: "employment",
          claim: claim_with_match,
          passed: true,
          claim_verifier_match: :all,
          manual: false
        )

        form = described_class.new(
          policy_name: "early_years_payments",
          statuses: {"employment" => ["passed"]}
        )

        expect(form.claims.map(&:reference)).to contain_exactly(
          claim_with_match.reference
        )
      end
    end

    context "when employment task has no_match status and all default filters are applied" do
      it "includes the claim in results" do
        claim = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )

        create(
          :task, :claim_verifier_context,
          name: "employment",
          claim: claim,
          passed: nil,
          claim_verifier_match: :none,
          manual: false,
          created_by: nil
        )

        form = described_class.new(policy_name: "early_years_payments")

        expect(form.claims.map(&:reference)).to include(claim.reference)
      end
    end

    context "when all default filters are applied" do
      it "includes claims with every student loan plan status" do
        claim_with_passed_status = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )
        create(
          :task,
          :passed,
          name: "student_loan_plan",
          claim: claim_with_passed_status
        )

        claim_with_failed_status = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )
        create(
          :task,
          :failed,
          name: "student_loan_plan",
          claim: claim_with_failed_status
        )

        claim_with_no_match_status = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )
        create(
          :task,
          :claim_verifier_context,
          name: "student_loan_plan",
          claim: claim_with_no_match_status,
          passed: nil,
          claim_verifier_match: :none,
          manual: false,
          created_by: nil
        )

        claim_with_no_data_status = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )
        create(
          :task,
          :claim_verifier_context,
          name: "student_loan_plan",
          claim: claim_with_no_data_status,
          passed: nil,
          claim_verifier_match: nil,
          manual: false,
          created_by: nil
        )

        claim_with_incomplete_status = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current
        )

        form = described_class.new(policy_name: "early_years_payments")

        expect(form.claims.map(&:reference)).to include(
          claim_with_passed_status.reference,
          claim_with_failed_status.reference,
          claim_with_no_match_status.reference,
          claim_with_no_data_status.reference,
          claim_with_incomplete_status.reference
        )
      end

      it "includes claims with an identity partial match status" do
        claim = create(
          :claim,
          policy: Policies::TargetedRetentionIncentivePayments,
          academic_year: AcademicYear.current
        )
        create(
          :task,
          :claim_verifier_context,
          name: "identity_confirmation",
          claim: claim,
          passed: nil,
          claim_verifier_match: :any,
          manual: false,
          created_by: nil
        )

        form = described_class.new(policy_name: "targeted_retention_incentive_payments")

        expect(form.claims.map(&:reference)).to include(claim.reference)
      end
    end

    context "when assignee filters are applied" do
      it "returns ClaimPresenters matching the filters" do
        assignee_1 = create(:dfe_signin_user, :service_operator)

        assignee_2 = create(:dfe_signin_user, :service_operator)

        claim_1 = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current,
          assigned_to: assignee_1
        )

        create(
          :task,
          :passed,
          name: "ey_eoi_cross_reference",
          claim: claim_1
        )

        create(
          :task,
          :failed,
          name: "employment",
          claim: claim_1
        )

        claim_2 = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          academic_year: AcademicYear.current,
          assigned_to: assignee_2
        )

        create(
          :task,
          :passed,
          name: "ey_eoi_cross_reference",
          claim: claim_2
        )

        create(
          :task,
          :failed,
          name: "employment",
          claim: claim_2
        )

        form = described_class.new(
          policy_name: "early_years_payments",
          assignee_id: assignee_1.id
        )

        expect(form.claims.map(&:reference)).to contain_exactly(
          claim_1.reference
        )
      end
    end
  end

  describe "#task_statuses" do
    it "returns match-based statuses for employment" do
      form = described_class.new(policy_name: "early_years_payments")
      expect(form.task_statuses("employment")).to eq(
        %w[passed failed no_match no_data incomplete not_applicable]
      )
    end

    it "returns match-based statuses for identity confirmation" do
      form = described_class.new(policy_name: "targeted_retention_incentive_payments")
      expect(form.task_statuses("identity_confirmation")).to eq(
        %w[passed failed partial_match no_match incomplete not_applicable]
      )
    end

    it "returns match-based statuses for qualifications" do
      form = described_class.new(policy_name: "targeted_retention_incentive_payments")
      expect(form.task_statuses("qualifications")).to eq(
        %w[passed failed no_match incomplete not_applicable]
      )
    end

    it "returns no-data statuses for census subjects taught" do
      form = described_class.new(policy_name: "targeted_retention_incentive_payments")
      expect(form.task_statuses("census_subjects_taught")).to eq(
        %w[passed failed no_match no_data incomplete not_applicable]
      )
    end

    it "returns no-data statuses for student loan plan" do
      form = described_class.new(policy_name: "early_years_payments")
      expect(form.task_statuses("student_loan_plan")).to eq(
        %w[passed failed no_match no_data incomplete not_applicable]
      )
    end

    it "returns standard statuses for non-employment tasks" do
      form = described_class.new(policy_name: "early_years_payments")
      expect(form.task_statuses("ey_eoi_cross_reference")).to eq(
        %w[passed failed incomplete not_applicable]
      )
    end

    it "returns standard statuses for payroll gender" do
      form = described_class.new(policy_name: "early_years_payments")
      expect(form.task_statuses("payroll_gender")).to eq(
        %w[passed failed incomplete not_applicable]
      )
    end
  end
end
