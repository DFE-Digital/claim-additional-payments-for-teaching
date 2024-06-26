require "rails_helper"

module AutomatedChecks
  module ClaimVerifiers
    RSpec.describe Induction do
      subject(:induction_task) { described_class.new(**induction_task_args) }

      let(:induction_task_args) do
        {
          claim: claim_arg,
          dqt_teacher_status: Dqt::Client.new.teacher.find(
            claim_arg.eligibility.teacher_reference_number,
            birthdate: claim_arg.date_of_birth,
            nino: claim_arg.national_insurance_number
          )
        }
      end

      let(:claim_arg) { ecp_claim }
      let(:ecp_claim) { create(:claim, :submitted, policy: policy) }
      let(:policy) { Policies::EarlyCareerPayments }

      before do
        if defined?(data) && data
          body = data
          status = 200
        else
          body = {}
          status = 404
        end

        stub_qualified_teaching_statuses_show(
          trn: claim_arg.eligibility.teacher_reference_number,
          params: {
            birthdate: claim_arg.date_of_birth&.to_s,
            nino: claim_arg.national_insurance_number
          },
          body: body,
          status: status
        )
      end

      shared_examples :successful_execution do
        let(:saved_task) { claim_arg.tasks.find_by(name: "induction_confirmation") }
        let(:saved_note) { claim_arg.notes.last }

        it "saves a task" do
          expect { perform }.to change(Task, :count).by(1)
        end

        it "marks the task based on the induction data from the DQT response" do
          perform

          expect(saved_task).to have_attributes(
            name: "induction_confirmation",
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

        it "saves the result of the DQT response on the note" do
          perform

          expect(saved_note).to have_attributes(
            body: expected_note,
            label: "induction_confirmation",
            created_by_id: nil
          )
        end
      end

      describe "#perform" do
        subject(:perform) { induction_task.perform }

        context "when the claim policy is not ECP" do
          [Policies::LevellingUpPremiumPayments, Policies::StudentLoans].each do |policy|
            context "when the policy is #{policy}" do
              let(:policy) { policy }

              it "returns immediately", :aggregate_failures do
                is_expected.to be_nil

                expect { perform }.not_to change(Task, :count)
                expect { perform }.not_to change(Note, :count)
              end
            end
          end
        end

        context "without matching DQT record" do
          let(:data) { nil }

          let(:expected_to_pass?) { nil }
          let(:expected_match_value) { nil }
          let(:expected_note) { "[DQT Induction] - No data" }

          it_behaves_like :successful_execution
        end

        context "with incomplete induction data" do
          let(:data) do
            {
              induction: {
                start_date: nil,
                completion_date: nil,
                status: "Pass"
              },
              initial_teacher_training: {
                programme_start_date: "2020-09-01T00:00:00Z",
                qualification: "Degree"
              }
            }
          end

          let(:expected_to_pass?) { nil }
          let(:expected_match_value) { nil }
          let(:expected_note) do
            <<~HTML
              [DQT Induction] - No data:
              <pre>
                Start date:      N/A
                Completion date: N/A
                Status:          Pass
              </pre>
            HTML
          end

          it_behaves_like :successful_execution
        end

        context "with ineligible induction data from the DQT response" do
          let(:data) do
            {
              induction: {
                start_date: "2021-07-01T00:00:00Z",
                completion_date: "2022-07-05T00:00:00Z",
                status: "Failed"
              }
            }
          end

          let(:expected_to_pass?) { nil }
          let(:expected_match_value) { "none" }
          let(:expected_note) do
            <<~HTML
              [DQT Induction] - Ineligible:
              <pre>
                Start date:      #{Date.parse("2021-07-01")}
                Completion date: #{Date.parse("2022-07-05")}
                Status:          Failed
              </pre>
            HTML
          end

          it_behaves_like :successful_execution
        end

        context "with eligible induction data from the DQT response" do
          let(:data) do
            {
              induction: {
                start_date: "2019-07-01T00:00:00Z",
                completion_date: "2020-07-05T00:00:00Z",
                status: "Pass"
              },
              initial_teacher_training: {
                programme_start_date: "2020-07-01T00:00:00Z",
                qualification: "Degree"
              }
            }
          end

          let(:expected_to_pass?) { true }
          let(:expected_match_value) { "all" }
          let(:expected_note) do
            <<~HTML
              [DQT Induction] - Eligible:
              <pre>
                Start date:      #{Date.parse("2019-07-01")}
                Completion date: #{Date.parse("2020-07-05")}
                Status:          Pass
              </pre>
            HTML
          end

          it_behaves_like :successful_execution
        end
      end
    end
  end
end
