module Journeys
  class Session < ApplicationRecord
    self.abstract_class = true

    self.table_name = "journeys_sessions"

    has_one :claim,
      dependent: :nullify,
      inverse_of: :journey_session,
      foreign_key: :journeys_session_id

    validates :journey,
      presence: true,
      inclusion: {in: Journeys.all_routing_names}

    scope :unsubmitted, -> { where.missing(:claim) }

    scope :submitted, -> { joins(:claim) }

    scope :purgeable, -> do
      unsubmitted.where(journeys_sessions: {updated_at: ..24.hours.ago})
    end

    def journey_class
      Journeys.for_routing_name(journey)
    end

    def submitted?
      claim.present?
    end

    def logged_in_with_tid_and_has_recent_tps_school?
      answers.trn_from_tid? && recent_tps_school.present?
    end

    # NOTE getting the trn from answers.teacher_id_user_info was the previous
    # implementation, TODO switch to `answers.teacher_reference_number` as it's
    # set in the sign in or continue form at the same time.
    def recent_tps_school
      @recent_tps_school ||= TeachersPensionsService.recent_tps_school(
        claim_date: created_at,
        teacher_reference_number: answers.teacher_id_user_info["trn"]
      )
    end

    def has_tps_school_for_student_loan_in_previous_financial_year?
      tps_school_for_student_loan_in_previous_financial_year.present?
    end

    def tps_school_for_student_loan_in_previous_financial_year
      @tps_school_for_student_loan_in_previous_financial_year ||=
        TeachersPensionsService.tps_school_for_student_loan_in_previous_financial_year(
          teacher_reference_number: answers.teacher_id_user_info["trn"]
        )
    end
  end
end
