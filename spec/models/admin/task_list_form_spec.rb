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

    context "when assignee filters are applied" do
      it "returns ClaimPresenters matching the filters" do
        assignee_1 = create(:dfe_signin_user, :support_agent)

        assignee_2 = create(:dfe_signin_user, :support_agent)

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
end
