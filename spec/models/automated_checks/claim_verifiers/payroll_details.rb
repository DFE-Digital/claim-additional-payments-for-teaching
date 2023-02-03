require "rails_helper"

module AutomatedChecks
  module ClaimVerifiers
    RSpec.describe PayrollDetails do
      let(:claim) { create(:claim, trait) }

      subject(:verifier) { described_class.new(claim: claim) }

      describe "#perform" do
        subject(:result) { verifier.perform }

        context "when the bank details have been validated" do
          let(:trait) { :bank_details_validated }

          context "when the claim already has a payroll details task" do
            before { create(:task, claim: claim, name: "payroll_details") }

            it { is_expected.to be_nil }

            it "does not create a task" do
              expect { result }.not_to change { claim.reload.tasks.count }
            end
          end

          context "when the claim does not already have a payroll details task" do
            it { is_expected.to be_nil }

            it "does not create a task" do
              expect(claim.reload.tasks.count).to be_zero
            end
          end
        end

        context "when the bank details have not been validated" do
          let(:trait) { :bank_details_not_validated }

          context "when the claim already has a payroll details task" do
            before { create(:task, claim: claim, name: "payroll_details") }

            it { is_expected.to be_nil }

            it "does not create a task" do
              expect { result }.not_to change { claim.reload.tasks.count }
            end
          end

          context "when the claim does not already have a payroll details task" do
            it { is_expected.to be_a(Task) }

            it "creates a task" do
              result
              expect(claim.reload.tasks.count).to eq(1)
              expect(claim.reload.tasks.first.name).to eq("payroll_details")
              expect(claim.reload.tasks.first.manual).to eq(true)
            end
          end
        end
      end
    end
  end
end
