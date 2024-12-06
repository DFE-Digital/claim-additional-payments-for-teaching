require "rails_helper"

RSpec.describe Reminders::EmailVerificationForm do
  let!(:journey_configuration) do
    create(:journey_configuration, :further_education_payments)
  end

  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) do
    create(
      :further_education_payments_session,
      answers: {
        reminder_full_name: "John Doe",
        reminder_email_address: "john.doe@example.com"
      }
    )
  end

  subject do
    described_class.new(
      journey_session:,
      journey:,
      params: ActionController::Parameters.new,
      session: {}
    )
  end

  describe "#save!" do
    let(:fake_passing_validator) { OpenStruct.new(valid?: true) }

    before do
      allow(OneTimePassword::Validator).to receive(:new).and_return(fake_passing_validator)
    end

    context "when reminder previously soft deleted" do
      let!(:reminder) do
        create(
          :reminder,
          :soft_deleted,
          full_name: "John Doe",
          email_address: "john.doe@example.com",
          email_verified: true,
          itt_subject: nil,
          itt_academic_year: journey_configuration.current_academic_year.succ,
          journey_class: journey.to_s
        )
      end

      it "becomes undeleted" do
        expect {
          subject.save!
        }.to change { reminder.reload.deleted_at }.to(nil)
      end
    end
  end
end
