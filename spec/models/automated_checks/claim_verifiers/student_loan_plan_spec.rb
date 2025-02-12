require "rails_helper"

module AutomatedChecks
  module ClaimVerifiers
    RSpec.describe StudentLoanPlan do
      subject(:student_loan_plan_task) { described_class.new(**student_loan_plan_task_args) }

      let(:student_loan_plan_task_args) { {claim: claim_arg} }

      let(:claim_arg) { claim }
      let(:claim) { create(:claim, :submitted, policy:) }

      shared_examples :creating_a_task_and_note do
        let(:saved_task) { claim_arg.tasks.find_by(name: "student_loan_plan") }
        let(:saved_note) { claim_arg.notes.last }

        it "saves a task" do
          expect { perform }.to change(Task, :count).by(1)
        end

        it "marks the task as expected" do
          perform

          expect(saved_task).to have_attributes(
            name: "student_loan_plan",
            passed: expected_to_pass?,
            manual: false,
            created_by_id: nil,
            claim_verifier_match: expected_match_value
          )
        end

        it "returns the saved task" do
          is_expected.to eq(saved_task)
        end

        it "saves a note" do
          expect { perform }.to change(Note, :count).by(1)
        end

        it "saves the outcome on the note" do
          perform

          expect(saved_note).to have_attributes(
            body: expected_note,
            label: "student_loan_plan",
            created_by_id: nil
          )
        end
      end

      shared_examples :creating_a_note_but_no_task do
        let(:saved_note) { claim_arg.notes.last }

        it "does not create a task" do
          expect { perform }.not_to change(Task, :count)
        end

        it "saves a note" do
          expect { perform }.to change(Note, :count).by(1)
        end

        it "saves the outcome on the note" do
          perform

          expect(saved_note).to have_attributes(
            body: expected_note,
            label: "student_loan_plan",
            created_by_id: nil
          )
        end
      end

      shared_examples :not_creating_a_task_or_note do
        it "does not save anything and returns immediately", :aggregate_failures do
          is_expected.to be_nil

          expect { perform }.not_to change(Task, :count)
          expect { perform }.not_to change(Note, :count)
        end
      end

      shared_examples :raising_an_error do
        it "raises an error" do
          expect { perform }.to raise_error(
            described_class::MissingClaimPlanError,
            "Claim #{claim.reference} has no student loan plan set. " \
            "but student loan data with matching DOB and NINO was found"
          )
        end
      end

      describe "#perform" do
        subject(:perform) { student_loan_plan_task.perform }

        context "when the claim policy is TSLR" do
          let(:policy) { Policies::StudentLoans }

          it_behaves_like :not_creating_a_task_or_note
        end

        [Policies::LevellingUpPremiumPayments, Policies::EarlyCareerPayments, Policies::FurtherEducationPayments].each do |policy|
          context "when the policy is #{policy}" do
            let(:policy) { policy }
            let(:claim) { create(:claim, :submitted, policy:, national_insurance_number: "QQ123456A", has_student_loan: true, student_loan_plan: claim_student_loan_plan, submitted_using_slc_data:) }
            let(:claim_student_loan_plan) { StudentLoan::PLAN_1 }

            context "when there is already a student_loan_plan task" do
              before { create(:task, claim: claim, name: "student_loan_plan") }

              let(:submitted_using_slc_data) { false }

              it_behaves_like :not_creating_a_task_or_note
            end

            context "when the claim was submitted using SLC data" do
              let(:submitted_using_slc_data) { true }

              it_behaves_like :not_creating_a_task_or_note
            end

            context "when the claim was not submitted using SLC data" do
              let(:submitted_using_slc_data) { false }

              context "when there is no student loan data for the claim" do
                let(:expected_note) { "[SLC Student loan plan] - SLC data checked, no matching entry found" }

                it_behaves_like :creating_a_note_but_no_task
              end

              context "when there is student loan data - with a plan" do
                before do
                  create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth, plan_type_of_deduction: 1)
                end

                let(:expected_to_pass?) { true }
                let(:expected_match_value) { "all" }
                let(:expected_note) { "[SLC Student loan plan] - Matched - has a student loan" }

                context "when the claim has a student_loan_plan" do
                  let(:claim_student_loan_plan) { StudentLoan::PLAN_1 }
                  it_behaves_like :creating_a_task_and_note
                end

                context "when the claim does not have a student_loan_plan" do
                  let(:claim_student_loan_plan) { nil }
                  it_behaves_like :raising_an_error
                end
              end

              context "when there is student loan data - without a plan" do
                before do
                  create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth, plan_type_of_deduction: nil)
                end

                let(:expected_to_pass?) { true }
                let(:expected_match_value) { "all" }
                let(:expected_note) { "[SLC Student loan plan] - Matched - does not have a student loan" }

                it_behaves_like :creating_a_task_and_note
              end

              context "when there is student loan data matching only the NiNo, but not the DOB" do
                before do
                  create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth + 1.year)
                end

                let(:expected_to_pass?) { nil }
                let(:expected_match_value) { "none" }
                let(:expected_note) { "[SLC Student loan plan] - No match - DOB does not match" }

                it_behaves_like :creating_a_task_and_note
              end
            end

            # this will only happen for FE claims submitted before LUPEYALPHA-1010 was merged
            context "when a claim was submitted with submitted_using_slc_data: nil" do
              let(:submitted_using_slc_data) { nil }

              context "when there is no student loan data for the claim" do
                let(:expected_note) { "[SLC Student loan plan] - SLC data checked, no matching entry found" }

                it_behaves_like :creating_a_note_but_no_task
              end

              context "when there is student loan data - with a plan" do
                before do
                  create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth, plan_type_of_deduction: 1)
                end

                let(:expected_to_pass?) { true }
                let(:expected_match_value) { "all" }
                let(:expected_note) { "[SLC Student loan plan] - Matched - has a student loan" }

                it_behaves_like :creating_a_task_and_note
              end

              context "when there is student loan data - without a plan" do
                before do
                  create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth, plan_type_of_deduction: nil)
                end

                let(:expected_to_pass?) { true }
                let(:expected_match_value) { "all" }
                let(:expected_note) { "[SLC Student loan plan] - Matched - does not have a student loan" }

                it_behaves_like :creating_a_task_and_note
              end
            end
          end
        end
      end
    end
  end
end
