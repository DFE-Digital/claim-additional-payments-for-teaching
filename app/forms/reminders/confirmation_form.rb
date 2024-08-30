module Reminders
  class ConfirmationForm < Form
    def reminder
      @reminder ||= Reminder.find_by(
        full_name: journey_session.answers.reminder_full_name,
        email_address: journey_session.answers.reminder_email_address,
        email_verified: true,
        itt_academic_year: next_academic_year.to_s
      )
    end

    private

    def next_academic_year
      AcademicYear.next
    end
  end
end
