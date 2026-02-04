require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::ClaimantCheck do
  describe "#perform" do
    let(:previous_claim) { create(:claim) }

    let(:claimant_flag) do
      create(
        :claimant_flag,
        policy: claim.policy,
        identification_attribute: "national_insurance_number",
        identification_value: "AB123456C",
        reason: "clawback",
        suggested_action: "speak to manager",
        previous_claim: previous_claim
      )
    end

    before do
      claimant_flag
    end

    context "when a claim matches a flag" do
      let(:claim) do
        create(
          :claim,
          :further_education,
          national_insurance_number: "AB123456C"
        )
      end

      context "when a task has already been created" do
        before do
          create(
            :task,
            name: "claimant_check",
            claim: claim
          )
        end

        it "doesn't create a duplicate task" do
          expect { described_class.new(claim: claim).perform }.not_to(
            change(Task, :count)
          )
        end
      end

      context "when a task has not already been created" do
        it "creates a task with the correct attributes" do
          expect { described_class.new(claim: claim).perform }.to(
            change(
              claim.tasks.where(name: "claimant_check"),
              :count
            ).from(0).to(1)
          )

          task = claim.tasks.find_by!(name: "claimant_check")

          expect(task.manual).to be_falsey
          expect(task.passed).to be_nil
          expect(task.data["flags"]).to match_array(
            [
              {
                "claimant_match_on" => "national_insurance_number",
                "reason" => "clawback",
                "suggested_action" => "speak to manager",
                "flag_id" => claimant_flag.id
              }
            ]
          )
        end
      end
    end

    context "when a claim does not match a flag" do
      let(:claim) do
        create(
          :claim,
          :further_education,
          national_insurance_number: "AB123456B"
        )
      end

      it "does not create a task" do
        expect { described_class.new(claim: claim).perform }.not_to(
          change(Task, :count)
        )
      end
    end
  end
end
