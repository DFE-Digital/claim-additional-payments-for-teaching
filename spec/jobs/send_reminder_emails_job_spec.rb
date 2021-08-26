require "rails_helper"

RSpec.describe SendReminderEmailsJob do
  let(:count) { [*1..5].sample }
  let(:reminders) { create_list(:reminder, count, email_verified: true, itt_academic_year: AcademicYear.current) }
  before do
    # these should not send
    create(:reminder, email_verified: false)
    create(:reminder, email_verified: true, email_sent_at: Time.now)
    create(:reminder, email_verified: true, itt_academic_year: AcademicYear.next)
  end

  describe "#perform" do
    it "sends correct email to correct addresses" do
      # reminder emails to be sent have blank sent_at's
      reminders.each do |reminder|
        expect(reminder.email_sent_at).to eq(nil)
      end

      # perform job
      expect {
        perform_enqueued_jobs do
          subject.perform
        end
      }.to change { ActionMailer::Base.deliveries.count }.by(count)

      # check email body is correct
      reminder_email = ActionMailer::Base.deliveries.find { |email| email.to[0] == reminders.first.email_address }
      expect(reminder_email.body.to_s).to include("Dear #{reminders.first.full_name},\n\nThe #{AcademicYear.current} early-career payment window is now open.")

      # reminder emails once sent have sent_at's
      reminders.each do |reminder|
        expect(reminder.reload.email_sent_at).to_not eq(nil)
      end
    end
  end
end
