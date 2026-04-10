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
        expect(claim_1_presenter.task("ey_alternative_verification").status).to eq("na")
        expect(claim_1_presenter.task("employment").status).to eq("failed")
        expect(claim_1_presenter.task("student_loan_plan").status).to eq("incomplete")
        expect(claim_1_presenter.task("payroll_details").status).to eq("incomplete")
        expect(claim_1_presenter.task("payroll_gender").status).to eq("incomplete")

        expect(claim_2_presenter.task("ey_eoi_cross_reference").status).to eq("failed")
        expect(claim_2_presenter.task("one_login_identity").status).to eq("incomplete")
        expect(claim_2_presenter.task("ey_alternative_verification").status).to eq("na")
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
        %w[passed failed no_match no_data incomplete]
      )
    end

    it "returns standard statuses for non-employment tasks" do
      form = described_class.new(policy_name: "early_years_payments")
      expect(form.task_statuses("ey_eoi_cross_reference")).to eq(
        %w[passed failed incomplete]
      )
    end
  end

  describe Admin::TaskListForm::ClaimPresenter::Task do
    describe "#filter_status" do
      it "returns 'no_match' for employment tasks with 'no match' status" do
        task = described_class.new("employment", "No match", "red")
        expect(task.filter_status).to eq("no_match")
      end

      it "returns 'no_data' for employment tasks with 'no data' status" do
        task = described_class.new("employment", "No data", "red")
        expect(task.filter_status).to eq("no_data")
      end

      it "returns 'passed' for employment tasks with 'passed' status" do
        task = described_class.new("employment", "Passed", "green")
        expect(task.filter_status).to eq("passed")
      end

      it "returns 'failed' for employment tasks with 'failed' status" do
        task = described_class.new("employment", "Failed", "red")
        expect(task.filter_status).to eq("failed")
      end

      it "returns 'incomplete' for employment tasks with 'na' status" do
        task = described_class.new("employment", "na", "blue")
        expect(task.filter_status).to eq("incomplete")
      end

      it "returns 'incomplete' for non-employment tasks with 'no data' status" do
        task = described_class.new("census_subjects_taught", "No data", "red")
        expect(task.filter_status).to eq("incomplete")
      end

      it "returns 'incomplete' for non-employment tasks with 'na' status" do
        task = described_class.new("identity_confirmation", "na", "blue")
        expect(task.filter_status).to eq("incomplete")
      end
    end
  end
end
