require "rails_helper"

RSpec.describe AutomatedChecks::UpdateAdminClaimTasksWithDqt do
  subject(:dqt_api_consumer) do
    described_class.new(
      claim: claim,
      dqt_teacher_status: Dqt::Client.new.api.qualified_teaching_status.show(
        params: {
          teacher_reference_number: claim.teacher_reference_number,
          national_insurance_number: claim.national_insurance_number
        }
      )
    )
  end

  before { stub_qualified_teaching_status_show(claim: claim) }

  describe "#perform" do
    before { dqt_api_consumer.perform }

    context "with claim with eligible DQT record" do
      let(:claim) {
        create(
          :claim,
          :submitted,
          surname: "ELIGIBLE",
          teacher_reference_number: "1234567",
          reference: "AB123456",
          date_of_birth: Date.new(1990, 8, 23)
        )
      }

      describe "qualifications task" do
        subject(:qualifications_task) { claim.tasks.find_by!(name: "qualifications") }

        describe "#passed" do
          subject(:passed) { qualifications_task.passed }

          it { is_expected.to eq true }
        end

        describe "#manual" do
          subject(:manual) { qualifications_task.manual }

          it { is_expected.to eq false }
        end
      end

      describe "identity confirmation task" do
        subject(:identity_confirmation_task) { claim.tasks.find_by!(name: "identity_confirmation") }

        describe "#passed" do
          subject(:passed) { identity_confirmation_task.passed }

          it { is_expected.to eq true }
        end

        describe "#manual" do
          subject(:manual) { identity_confirmation_task.manual }

          it { is_expected.to eq false }
        end
      end
    end
  end
end
