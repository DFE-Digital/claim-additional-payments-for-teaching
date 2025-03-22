require "rails_helper"

RSpec.describe Tasks do
  describe ".status" do
    subject { Tasks.status(claim: claim, task_name: task_name) }

    context "with a generic task" do
      let(:claim) { create(:claim, :submitted) }
      let(:task_name) { "identity_confirmation" }

      context "when the task does not exist" do
        it "returns incomplete status with grey color" do
          status, color = Tasks.status(claim: claim, task_name: task_name)
          expect(status).to eq("Incomplete")
          expect(color).to eq("grey")
        end
      end

      context "when the task has passed" do
        before do
          create(:task, :passed, claim: claim, name: task_name)
        end

        it { is_expected.to eq(["Passed", "green"]) }
      end

      context "when the task has failed" do
        before do
          create(:task, :failed, claim: claim, name: task_name)
        end

        it { is_expected.to eq(["Failed", "red"]) }
      end

      context "when the task has full match from claim verifier" do
        before do
          create(
            :task,
            :claim_verifier_context,
            claim: claim,
            name: task_name,
            passed: nil,
            claim_verifier_match: "all"
          )
        end

        it { is_expected.to eq(["Full match", "green"]) }
      end

      context "when the task has partial match from claim verifier" do
        before do
          create(
            :task,
            :claim_verifier_context,
            claim: claim,
            name: task_name,
            passed: nil,
            claim_verifier_match: "any"
          )
        end

        it { is_expected.to eq(["Partial match", "yellow"]) }
      end

      context "when the task has no match from claim verifier" do
        before do
          create(
            :task,
            :claim_verifier_context,
            claim: claim,
            name: task_name,
            passed: nil,
            claim_verifier_match: "none"
          )
        end

        it { is_expected.to eq(["No match", "red"]) }
      end

      context "when specific tasks have no data" do
        ["census_subjects_taught", "employment", "induction_confirmation", "student_loan_amount", "student_loan_plan"].each do |special_task_name|
          context "with #{special_task_name} task" do
            let(:task_name) { special_task_name }

            before do
              create(
                :task,
                :claim_verifier_context,
                claim: claim,
                name: task_name,
                passed: nil,
                claim_verifier_match: nil
              )
            end

            it { is_expected.to eq(["No data", "red"]) }
          end
        end
      end

      # FIXME determine what we should do in this scenario, this was the
      # existing behaviour
      context "when a non-specific task has no claim verifier match" do
        let(:task_name) { "payroll_details" }

        before do
          create(
            :task,
            :claim_verifier_context,
            claim: claim,
            name: task_name,
            passed: nil,
            claim_verifier_match: nil
          )
        end

        it { is_expected.to eq([nil, nil]) }
      end
    end

    context "with an alternative_identity_verification task" do
      let(:task_name) { "alternative_identity_verification" }

      let(:claim) do
        create(:claim, :submitted, policy: Policies::FurtherEducationPayments)
      end

      context "when the task hasn't been created" do
        context "when the provider has submitted the verification" do
          before do
            create(
              :further_education_payments_eligibility,
              :identity_verified_by_provider,
              claim: claim
            )
          end

          it { is_expected.to eq(["No match", "red"]) }
        end

        context "when the provider has not submitted the verification" do
          it { is_expected.to eq(["Incomplete", "grey"]) }
        end
      end

      context "when the task has passed" do
        before do
          create(:task, :passed, claim: claim, name: task_name)
        end

        it { is_expected.to eq(["Passed", "green"]) }
      end

      context "when the task has failed" do
        before do
          create(:task, :failed, claim: claim, name: task_name)
        end

        it { is_expected.to eq(["Failed", "red"]) }
      end
    end
  end
end
