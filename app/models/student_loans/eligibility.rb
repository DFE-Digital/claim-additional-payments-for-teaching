# frozen_string_literal: true

module StudentLoans
  class Eligibility < ApplicationRecord
    SUBJECT_ATTRIBUTES = [
      :biology_taught,
      :chemistry_taught,
      :physics_taught,
      :computer_science_taught,
      :languages_taught,
    ].freeze

    self.table_name = "student_loans_eligibilities"

    enum qts_award_year: {
      "before_september_2013": 0,
      "on_or_after_september_2013": 1,
    }, _prefix: :awarded_qualified_status

    enum employment_status: {
      claim_school: 0,
      different_school: 1,
      no_school: 2,
    }, _prefix: :employed_at

    belongs_to :claim_school, optional: true, class_name: "School"
    belongs_to :current_school, optional: true, class_name: "School"

    validates :qts_award_year, on: [:"qts-year", :submit], presence: {message: "Select the academic year you were awarded qualified teacher status"}
    validates :claim_school, on: [:"claim-school", :submit], presence: {message: "Select a school from the list"}
    validates :employment_status, on: [:"still-teaching", :submit], presence: {message: "Choose the option that describes your current employment status"}
    validates :current_school, on: [:"current-school", :submit], presence: {message: "Select a school from the list"}
    validate :one_subject_must_be_selected, on: [:"subjects-taught", :submit], unless: :not_taught_eligible_subjects?
    validates :had_leadership_position, on: [:"leadership-position", :submit], inclusion: {in: [true, false], message: "Select either Yes or No"}
    validates :mostly_performed_leadership_duties, on: [:"mostly-performed-leadership-duties", :submit], inclusion: {in: [true, false], message: "Select either Yes or No"}, if: :had_leadership_position?
    validates :student_loan_repayment_amount, on: [:"student-loan-amount", :submit], presence: {message: "Enter your student loan repayment amount"}
    validates_numericality_of :student_loan_repayment_amount, message: "Enter a valid monetary amount", allow_nil: true, greater_than: 0, less_than_or_equal_to: 99999

    delegate :name, to: :claim_school, prefix: true, allow_nil: true
    delegate :name, to: :current_school, prefix: true, allow_nil: true

    def subjects_taught
      SUBJECT_ATTRIBUTES.select { |attribute_name| public_send("#{attribute_name}?") }
    end

    def student_loan_repayment_amount=(value)
      super(value.to_s.gsub(/[£,\s]/, ""))
    end

    def ineligible?
      ineligible_qts_award_year? ||
        ineligible_claim_school? ||
        employed_at_no_school? ||
        current_school_closed? ||
        not_taught_eligible_subjects? ||
        not_taught_enough?
    end

    def ineligibility_reason
      [
        :ineligible_qts_award_year,
        :ineligible_claim_school,
        :employed_at_no_school,
        :current_school_closed,
        :not_taught_eligible_subjects,
        :not_taught_enough,
      ].find { |eligibility_check| send("#{eligibility_check}?") }
    end

    def award_amount
      student_loan_repayment_amount
    end

    private

    def ineligible_qts_award_year?
      awarded_qualified_status_before_september_2013?
    end

    def ineligible_claim_school?
      claim_school.present? && !claim_school.eligible_for_student_loans?
    end

    def not_taught_eligible_subjects?
      taught_eligible_subjects == false
    end

    def not_taught_enough?
      mostly_performed_leadership_duties == true
    end

    def one_subject_must_be_selected
      errors.add(:subjects_taught, "Choose a subject, or select No") if subjects_taught.empty?
    end

    def current_school_closed?
      current_school.present? && !current_school.open?
    end
  end
end
