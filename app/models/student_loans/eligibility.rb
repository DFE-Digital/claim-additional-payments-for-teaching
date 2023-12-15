# frozen_string_literal: true

module StudentLoans
  class Eligibility < ApplicationRecord
    SUBJECT_ATTRIBUTES = [
      :biology_taught,
      :chemistry_taught,
      :physics_taught,
      :computing_taught,
      :languages_taught
    ].freeze
    EDITABLE_ATTRIBUTES = [
      :qts_award_year,
      :claim_school_id,
      :employment_status,
      :current_school_id,
      :had_leadership_position,
      :taught_eligible_subjects,
      :mostly_performed_leadership_duties,
      :student_loan_repayment_amount,
      SUBJECT_ATTRIBUTES
    ].flatten.freeze
    AMENDABLE_ATTRIBUTES = %i[student_loan_repayment_amount].freeze
    ATTRIBUTE_DEPENDENCIES = {
      "claim_school_id" => ["taught_eligible_subjects", *SUBJECT_ATTRIBUTES, "employment_status", "current_school_id"],
      "had_leadership_position" => ["mostly_performed_leadership_duties"]
    }.freeze

    self.table_name = "student_loans_eligibilities"

    # Note: these mapped values for the `qts_award_year` integer values are symbolic and not to be taken literally,
    # in particular the "cut off date" is to be considered dynamic and based on the current financial/claim year.
    # You should simply consider 0 as the ineligible value and 1 as the eligible one.
    # We don't store claims with a `qts_award_year = 0` as the journey would have ended after the first question.
    enum qts_award_year: {
      before_cut_off_date: 0,
      on_or_after_cut_off_date: 1
    }, _prefix: :awarded_qualified_status

    enum employment_status: {
      claim_school: 0,
      different_school: 1,
      no_school: 2,
      recent_tps_school: 3
    }, _prefix: :employed_at

    has_one :claim, as: :eligibility, inverse_of: :eligibility
    belongs_to :claim_school, optional: true, class_name: "School"
    belongs_to :current_school, optional: true, class_name: "School"

    validates :qts_award_year, on: [:"qts-year", :submit], presence: {message: "Select when you completed your initial teacher training"}
    validates :claim_school, on: [:"claim-school", :submit], presence: {message: "Select a school from the list or search again for a different school"}
    validates :claim_school, on: [:"select-claim-school"], presence: {message: ->(object, _data) { object.select_claim_school_presence_error_message }}, unless: :claim_school_somewhere_else?
    validates :employment_status, on: [:"still-teaching", :submit], presence: {message: ->(object, _data) { "Select if you still work at #{object.claim_school_name}, another school or no longer teach in England" }}
    validates :current_school, on: [:"current-school", :submit], presence: {message: "Select a school from the list"}
    validate :one_subject_must_be_selected, on: [:"subjects-taught", :submit], unless: :not_taught_eligible_subjects?
    validates :had_leadership_position, on: [:"leadership-position", :submit], inclusion: {in: [true, false], message: "Select yes if you were employed in a leadership position"}
    validates :mostly_performed_leadership_duties, on: [:"mostly-performed-leadership-duties", :submit], inclusion: {in: [true, false], message: "Select yes if you spent more than half your working hours on leadership duties"}, if: :had_leadership_position?
    validates :student_loan_repayment_amount, on: [:"student-loan-amount", :submit], presence: {message: "Enter your student loan repayment amount"}
    validates_numericality_of :student_loan_repayment_amount, message: "Enter a valid monetary amount", allow_nil: true, greater_than: 0, less_than_or_equal_to: 99999
    validates :student_loan_repayment_amount, on: :amendment, award_range: {max: 5_000}

    delegate :name, to: :claim_school, prefix: true, allow_nil: true
    delegate :name, to: :current_school, prefix: true, allow_nil: true
    delegate :academic_year, to: :claim, prefix: true

    def policy
      StudentLoans
    end

    def subjects_taught
      SUBJECT_ATTRIBUTES.select { |attribute_name| public_send("#{attribute_name}?") }
    end

    def ineligible?
      ineligible_qts_award_year? ||
        ineligible_claim_school? ||
        employed_at_no_school? ||
        ineligible_current_school? ||
        not_taught_eligible_subjects? ||
        not_taught_enough?
    end

    def ineligibility_reason
      [
        :ineligible_qts_award_year,
        :ineligible_claim_school,
        :employed_at_no_school,
        :ineligible_current_school,
        :not_taught_eligible_subjects,
        :not_taught_enough
      ].find { |eligibility_check| send("#{eligibility_check}?") }
    end

    def award_amount
      student_loan_repayment_amount
    end

    def eligible_itt_subject
    end

    def reset_dependent_answers(reset_attrs = [])
      attrs = ineligible? ? changed.concat(reset_attrs) : changed

      ATTRIBUTE_DEPENDENCIES.each do |attribute_name, dependent_attribute_names|
        dependent_attribute_names.each do |dependent_attribute_name|
          write_attribute(dependent_attribute_name, nil) if attrs.include?(attribute_name)
        end
      end
    end

    def submit!
    end

    def ineligible_qts_award_year?
      awarded_qualified_status_before_cut_off_date?
    end

    def select_claim_school_presence_error_message
      I18n.t("student_loans.questions.claim_school_select_error", financial_year: StudentLoans.current_financial_year)
    end

    private

    def ineligible_claim_school?
      claim_school.present? && !claim_school.eligible_for_student_loans_as_claim_school?
    end

    def not_taught_eligible_subjects?
      taught_eligible_subjects == false
    end

    def not_taught_enough?
      mostly_performed_leadership_duties == true
    end

    def one_subject_must_be_selected
      errors.add(:subjects_taught, "Select if you taught Biology, Chemistry, Physics, Computing, Languages or you did not teach any of these subjects") if subjects_taught.empty?
    end

    def ineligible_current_school?
      current_school.present? && !current_school.eligible_for_student_loans_as_current_school?
    end
  end
end
