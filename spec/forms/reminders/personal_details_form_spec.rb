require "rails_helper"

RSpec.describe Reminders::PersonalDetailsForm do
  let!(:journey_configuration) do
    create(:journey_configuration, :further_education_payments)
  end

  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session) }
  let(:claim) { create(:claim, :submitted) }

  subject do
    described_class.new(
      journey_session:,
      journey:,
      params: ActionController::Parameters.new,
      session: {"submitted_claim_id" => claim.id}
    )
  end

  describe "#set_reminder_from_claim" do
    context "when reminder previously soft deleted" do
      let!(:reminder) do
        create(
          :reminder,
          :soft_deleted,
          full_name: claim.full_name,
          email_address: claim.email_address,
          email_verified: true,
          itt_subject: claim.eligible_itt_subject,
          itt_academic_year: journey_configuration.current_academic_year.succ,
          journey_class: journey.to_s
        )
      end

      it "becomes undeleted" do
        expect {
          subject.set_reminder_from_claim
        }.to change { reminder.reload.deleted_at }.to(nil)
      end
    end
  end
end
