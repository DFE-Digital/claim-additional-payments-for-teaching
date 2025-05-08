require "rails_helper"

RSpec.describe SendReminderEmailsJob do
  let(:count) { [*1..5].sample }
  let(:reminders) do
    create_list(
      :reminder,
      count,
      email_verified: true,
      itt_academic_year: AcademicYear.current,
      journey_class: Journeys::TargetedRetentionIncentivePayments.to_s
    )
  end

  before do
    # these should not send
    create(:reminder, email_verified: false, journey_class: Journeys::TargetedRetentionIncentivePayments.to_s)
    create(:reminder, email_verified: true, email_sent_at: Time.now, journey_class: Journeys::TargetedRetentionIncentivePayments.to_s)
    create(:reminder, email_verified: true, itt_academic_year: AcademicYear.next, journey_class: Journeys::TargetedRetentionIncentivePayments.to_s)
    create(:reminder, email_verified: true, itt_academic_year: AcademicYear.current, journey_class: Journeys::FurtherEducationPayments.to_s)
  end

  describe "#perform" do
    let(:mail) { ReminderMailer.reminder(reminders.first) }

    it "sends correct email to correct addresses" do
      # reminder emails to be sent have blank sent_at's
      reminders.each do |reminder|
        expect(reminder.email_sent_at).to eq(nil)
      end

      # perform job
      expect {
        perform_enqueued_jobs do
          subject.perform(Journeys::TargetedRetentionIncentivePayments.to_s)
        end
      }.to change { ActionMailer::Base.deliveries.count }.by(count)

      # check template id is correct
      expect(mail.template_id).to eq "a8a36571-f93b-4474-93e2-35775fa753a0"

      # reminder emails once sent have sent_at's
      reminders.each do |reminder|
        expect(reminder.reload.email_sent_at).to_not eq(nil)
      end
    end
  end
end
