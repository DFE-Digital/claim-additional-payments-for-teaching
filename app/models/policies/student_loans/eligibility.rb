# frozen_string_literal: true

module Policies
  module StudentLoans
    class Eligibility < ApplicationRecord
      include TeacherReferenceNumberValidation

      SUBJECT_ATTRIBUTES = [
        :biology_taught,
        :chemistry_taught,
        :physics_taught,
        :computing_taught,
        :languages_taught
      ].freeze
      AMENDABLE_ATTRIBUTES = %i[teacher_reference_number student_loan_repayment_amount].freeze

      self.table_name = "student_loans_eligibilities"

      # Note: these mapped values for the `qts_award_year` integer values are symbolic and not to be taken literally,
      # in particular the "cut off date" is to be considered dynamic and based on the current financial/claim year.
      # You should simply consider 0 as the ineligible value and 1 as the eligible one.
      # We don't store claims with a `qts_award_year = 0` as the journey would have ended after the first question.
      enum :qts_award_year, {
        before_cut_off_date: 0,
        on_or_after_cut_off_date: 1
      }, prefix: :awarded_qualified_status

      enum :employment_status, {
        claim_school: 0,
        different_school: 1,
        no_school: 2,
        recent_tps_school: 3
      }, prefix: :employed_at

      has_one :claim, as: :eligibility, inverse_of: :eligibility
      belongs_to :claim_school, optional: true, class_name: "School"
      belongs_to :current_school, optional: true, class_name: "School"

      before_validation :normalise_teacher_reference_number, if: :teacher_reference_number_changed?

      validates :claim_school, on: [:"select-claim-school"], presence: {message: ->(object, _data) { object.select_claim_school_presence_error_message }}, unless: :claim_school_somewhere_else?
      validates :employment_status, on: [:submit], presence: {message: ->(object, _data) { "Select if you still work at #{object.claim_school_name}, another school or no longer teach in England" }}
      validates :had_leadership_position, on: [:submit], inclusion: {in: [true, false], message: "Select yes if you were employed in a leadership position"}
      validates :mostly_performed_leadership_duties, on: [:submit], inclusion: {in: [true, false], message: "Select yes if you spent more than half your working hours on leadership duties"}, if: :had_leadership_position?
      validates_numericality_of :student_loan_repayment_amount, message: "Enter a valid monetary amount", allow_nil: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 99999
      validates :student_loan_repayment_amount, on: :amendment, award_range: {max: 5_000}, if: :student_loan_repayment_amount_changed?
      validates :teacher_reference_number, on: :amendment, presence: {message: "Enter your teacher reference number"}
      validate :validate_teacher_reference_number_length

      delegate :name, to: :claim_school, prefix: true, allow_nil: true
      delegate :name, to: :current_school, prefix: true, allow_nil: true
      delegate :academic_year, to: :claim, prefix: true

      delegate :has_student_loan, to: :claim

      def policy
        Policies::StudentLoans
      end

      def subjects_taught
        SUBJECT_ATTRIBUTES.select { |attribute_name| public_send(:"#{attribute_name}?") }
      end

      def ineligible?
        eligibility_checker.ineligible?
      end

      def ineligibility_reason
        eligibility_checker.ineligibility_reason
      end

      def award_amount
        student_loan_repayment_amount
      end

      def eligible_itt_subject
      end

      def submit!
      end

      def ineligible_qts_award_year?
        eligibility_checker.awarded_qualified_status_before_cut_off_date?
      end

      def select_claim_school_presence_error_message
        I18n.t("student_loans.questions.claim_school_select_error", financial_year: StudentLoans.current_financial_year)
      end

      private

      def eligibility_checker
        @eligibility_checker ||= PolicyEligibilityChecker.new(answers: self)
      end
    end
  end
end
