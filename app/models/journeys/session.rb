module Journeys
  class Session < ApplicationRecord
    self.abstract_class = true

    has_one :claim,
      dependent: :nullify,
      inverse_of: :journey_session,
      foreign_key: :journeys_session_id

    validates :journey,
      presence: true,
      inclusion: {in: Journeys.all_routing_names}

    def submitted?
      claim.present?
    end

    # This method and the associated `before_save` callback are temporary
    # methods while we're working with both a current claim and journey
    # session.
    # When setting default values in a form object we need to know if the
    # answer was stored on the journey session or whether we should check the
    # current claim. Values for answers may be `nil`, so we need to explicitly
    # check that the question was answered.
    # Once all forms has been migrated to use the journey session, this method,
    # the before_save and after_initialize call backs and the
    # SessionAnswer#answered attribute can be removed.
    # This will be removed in
    # https://dfedigital.atlassian.net.mcas.ms/browse/CAPT-1637
    def answered?(attribute_name)
      answers.answered.include?(attribute_name.to_s)
    end

    after_initialize do
      answers.clear_changes_information
    end

    before_save do
      unless answers.answered_changed? # Allow overwriting answered attributes
        answers.answered += answers.changes.keys.map(&:to_s)
      end
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
