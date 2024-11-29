module Reminders
  class ConfirmationForm < Form
    def reminder
      @reminder ||= if submitted_claim
        Reminder.find_by(
          full_name: submitted_claim.full_name,
          email_address: submitted_claim.email_address,
          email_verified: true,
          itt_subject: itt_subject_for_submitted_claim,
          itt_academic_year: next_academic_year.to_s,
          journey_class: journey.to_s
        )
      else
        Reminder.find_by(
          full_name: journey_session.answers.reminder_full_name,
          email_address: journey_session.answers.reminder_email_address,
          email_verified: true,
          itt_subject:,
          itt_academic_year: next_academic_year.to_s,
          journey_class: journey.to_s
        )
      end
    end

    def set_reminder_from_claim
    end

    private

    def itt_subject
      journey_session.answers.eligible_itt_subject
    end

    def itt_subject_for_submitted_claim
      submitted_claim.eligible_itt_subject
    end

    def submitted_claim
      Claim.find_by(id: session["submitted_claim_id"])
    end

    def next_academic_year
      journey.configuration.current_academic_year + 1
    end
  end
end
