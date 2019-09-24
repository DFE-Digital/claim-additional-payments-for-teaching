# frozen_string_literal: true

module StudentLoans
  class Employment < ApplicationRecord
    self.table_name = "student_loans_employments"

    SUBJECT_ATTRIBUTES = [
      :biology_taught,
      :chemistry_taught,
      :physics_taught,
      :computer_science_taught,
      :languages_taught,
    ].freeze

    belongs_to :eligibility, class_name: "Eligibility"
    belongs_to :school, class_name: "School"

    validate :one_subject_must_be_selected, on: [:"subjects-taught", :submit], unless: :not_taught_eligible_subjects?
    validates :student_loan_repayment_amount, on: [:"student-loan-amount", :submit], presence: {message: "Enter your student loan repayment amount"}
    validates_numericality_of :student_loan_repayment_amount, message: "Enter a valid monetary amount", allow_nil: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 99999

    delegate :name, to: :school, prefix: true, allow_nil: true

    def subjects_taught
      SUBJECT_ATTRIBUTES.select { |attribute_name| public_send("#{attribute_name}?") }
    end

    def student_loan_repayment_amount=(value)
      super(value.to_s.gsub(/[£,\s]/, ""))
    end

    def ineligible?
      ineligible_claim_school? ||
        not_taught_eligible_subjects?
    end

    def ineligibility_reason
      [
        :ineligible_claim_school,
        :not_taught_eligible_subjects,
      ].find { |eligibility_check| send("#{eligibility_check}?") }
    end

    private

    def ineligible_claim_school?
      school.present? && !school.eligible_for_student_loans?
    end

    def not_taught_eligible_subjects?
      taught_eligible_subjects == false
    end

    def one_subject_must_be_selected
      errors.add(:subjects_taught, "Choose a subject, or select No") if subjects_taught.empty?
    end
  end
end
