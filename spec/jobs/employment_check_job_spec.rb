require "rails_helper"

RSpec.describe EmploymentCheckJob do
  it { expect(described_class.new).to be_an(ApplicationJob) }

  describe "#perform" do
    subject(:job) { described_class.new }
    let(:verifier_instance) { instance_double("AutomatedChecks::ClaimVerifiers::Employment", perform: true) }
    let(:policy) { Policies::TargetedRetentionIncentivePayments }

    before do
      allow(AutomatedChecks::ClaimVerifiers::Employment).to receive(:new).with(claim:).and_return(verifier_instance)
    end

    let(:claim) { create(:claim, :submitted, policy:) }

    context "when there is a recent claim with a passed check" do
      let!(:passed_check) { create(:task, :passed, :automated, name: "employment", claim:) }

      before { job.perform }

      it "does not delete the existing check on that claim" do
        expect { passed_check.reload }.not_to raise_error
      end

      it "does not create a new employment check" do
        expect(AutomatedChecks::ClaimVerifiers::Employment).not_to have_received(:new)
      end
    end

    context "when there is a recent claim with a failed check" do
      let!(:failed_check) { create(:task, :failed, :automated, name: "employment", claim:) }

      before { job.perform }

      it "deletes the old check on that claim" do
        expect { failed_check.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "creates a new employment check on that claim" do
        expect(AutomatedChecks::ClaimVerifiers::Employment).to have_received(:new).with(claim:)
      end
    end

    context "when there is a claim over 3 months old with a failed employment check" do
      let(:academic_year) { create(:journey_configuration, routing_name: Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME).current_academic_year }
      let(:past_date) { Time.zone.local(academic_year.end_year, 3, 31) }
      let(:claim) { create(:claim, :submitted, policy:, submitted_at: past_date) }
      let!(:failed_check) { create(:task, :failed, :automated, name: "employment", claim:, created_at: past_date) }

      before do
        failed_check.update!(updated_at: past_date)
        travel_to(Time.zone.local(academic_year.end_year, 8, 31)) { job.perform }
      end

      it "deletes the existing check on that claim" do
        expect { failed_check.reload }.not_to raise_error
      end

      it "does not create a new employment check" do
        expect(AutomatedChecks::ClaimVerifiers::Employment).not_to have_received(:new)
      end
    end
  end
end
