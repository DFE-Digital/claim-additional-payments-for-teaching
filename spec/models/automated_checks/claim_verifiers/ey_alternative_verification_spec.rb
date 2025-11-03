require "rails_helper"

module AutomatedChecks
  module ClaimVerifiers
    RSpec.describe EyAlternativeVerification do
      subject(:verifier) { described_class.new(claim: claim) }

      let(:banking_name) { "John Smith" }
      let(:hmrc_bank_validation_responses) { [{"body" => {"nameMatches" => "yes"}}] }

      let(:claim) do
        create(
          :claim, :submitted,
          policy: Policies::EarlyYearsPayments,
          eligibility: eligibility,
          date_of_birth: Date.new(1990, 1, 15),
          postcode: "SW1A 1AA",
          national_insurance_number: "AB123456C",
          email_address: "teacher@example.com",
          first_name: "John",
          surname: "Smith",
          banking_name: banking_name,
          hmrc_bank_validation_responses: hmrc_bank_validation_responses
        )
      end

      let(:eligibility) do
        create(
          :early_years_payments_eligibility,
          :with_eligible_ey_provider,
          alternative_idv_claimant_employed_by_nursery: employed_by_nursery,
          alternative_idv_claimant_date_of_birth: provider_date_of_birth,
          alternative_idv_claimant_postcode: provider_postcode,
          alternative_idv_claimant_national_insurance_number: provider_nino,
          alternative_idv_claimant_email: provider_email,
          alternative_idv_claimant_bank_details_match: provider_bank_details_match
        )
      end

      let(:employed_by_nursery) { true }
      let(:provider_date_of_birth) { Date.new(1990, 1, 15) }
      let(:provider_postcode) { "SW1A 1AA" }
      let(:provider_nino) { "AB123456C" }
      let(:provider_email) { "teacher@example.com" }
      let(:provider_bank_details_match) { true }

      describe "#perform" do
        context "when a task already exists" do
          before { create(:task, name: "ey_alternative_verification", claim: claim) }

          it "does not create a new task" do
            expect { verifier.perform }.not_to change { claim.tasks.count }
          end
        end

        context "when provider says claimant is not employed by the nursery" do
          let(:employed_by_nursery) { false }

          it "creates a failed, non-manual task with empty data" do
            verifier.perform
            task = claim.tasks.find_by(name: "ey_alternative_verification")
            expect(task).to be_present
            expect(task.passed).to eq(false)
            expect(task.manual).to eq(false)
            expect(task.data).to eq({
              "personal_details_match" => false,
              "personal_details_task_completed_automatically" => true
            })
          end
        end

        context "when personal details match" do
          context "when bank details match" do
            let(:banking_name) { "  JOHN smith  " }

            it "auto-passes personal and bank checks and marks task passed" do
              verifier.perform
              task = claim.tasks.find_by(name: "ey_alternative_verification")
              expect(task.passed).to eq(true)
              expect(task.manual).to eq(false)
              expect(task.data).to eq(
                "personal_details_task_completed_automatically" => true,
                "personal_details_match" => true,
                "bank_details_task_completed_automatically" => true,
                "bank_details_match" => true
              )
            end
          end

          context "when bank details don't match what the provider has" do
            let(:provider_bank_details_match) { false }

            it "fails the task" do
              verifier.perform
              task = claim.tasks.find_by(name: "ey_alternative_verification")
              expect(task.passed).to eq false
              expect(task.manual).to eq false
              expect(task.data).to eq(
                "personal_details_task_completed_automatically" => true,
                "personal_details_match" => true,
                "bank_details_task_completed_automatically" => true,
                "bank_details_match" => false
              )
            end
          end

          context "when bank name doesn't match" do
            let(:banking_name) { "Jane Smith" }

            it "is incomplete with personal auto-pass only" do
              verifier.perform
              task = claim.tasks.find_by(name: "ey_alternative_verification")
              expect(task.passed).to be_nil
              expect(task.manual).to be_nil
              expect(task.data).to eq(
                "personal_details_task_completed_automatically" => true,
                "personal_details_match" => true
              )
            end
          end

          context "when hmrc response is not a pass" do
            let(:hmrc_bank_validation_responses) do
              [{"body" => {"nameMatches" => "no"}}]
            end

            it "is incomplete with personal auto-pass only" do
              verifier.perform
              task = claim.tasks.find_by(name: "ey_alternative_verification")
              expect(task.passed).to be_nil
              expect(task.manual).to be_nil
              expect(task.data).to eq(
                "personal_details_task_completed_automatically" => true,
                "personal_details_match" => true
              )
            end
          end
        end

        context "when personal details do not match but bank does" do
          let(:provider_date_of_birth) { Date.new(1991, 1, 15) }

          it "is incomplete and sets only the bank auto-pass flags" do
            verifier.perform
            task = claim.tasks.find_by(name: "ey_alternative_verification")
            expect(task.passed).to be_nil
            expect(task.manual).to be_nil
            expect(task.data).to eq(
              "bank_details_task_completed_automatically" => true,
              "bank_details_match" => true
            )
          end
        end
      end
    end
  end
end
