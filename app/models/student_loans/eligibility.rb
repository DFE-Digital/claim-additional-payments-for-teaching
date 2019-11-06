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
    EDITABLE_ATTRIBUTES = [
      :qts_award_year,
      :claim_school_id,
      :employment_status,
      :current_school_id,
      :had_leadership_position,
      :taught_eligible_subjects,
      :mostly_performed_leadership_duties,
      :student_loan_repayment_amount,
      SUBJECT_ATTRIBUTES,
    ].flatten.freeze
    ATTRIBUTE_DEPENDENCIES = {
      "claim_school_id" => ["taught_eligible_subjects", *SUBJECT_ATTRIBUTES, "employment_status"],
      "had_leadership_position" => ["mostly_performed_leadership_duties"],
    }.freeze

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
        :not_taught_enough,
      ].find { |eligibility_check| send("#{eligibility_check}?") }
    end

    def award_amount
      student_loan_repayment_amount
    end

    def reset_dependent_answers
      ATTRIBUTE_DEPENDENCIES.each do |attribute_name, dependent_attribute_names|
        dependent_attribute_names.each do |dependent_attribute_name|
          write_attribute(dependent_attribute_name, nil) if changed.include?(attribute_name)
        end
      end
      self.current_school = inferred_current_school if employment_status_changed?
    end

    private

    def ineligible_qts_award_year?
      awarded_qualified_status_before_september_2013?
    end

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
      errors.add(:subjects_taught, "Choose a subject, or select No") if subjects_taught.empty?
    end

    def ineligible_current_school?
      current_school.present? && !current_school.eligible_for_student_loans_as_current_school?
    end

    def inferred_current_school
      employed_at_claim_school? ? claim_school : nil
    end
  end
end
