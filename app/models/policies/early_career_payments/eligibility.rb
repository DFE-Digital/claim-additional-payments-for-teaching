module Policies
  module EarlyCareerPayments
    class Eligibility < ApplicationRecord
      include EligibilityCheckable

      EDITABLE_ATTRIBUTES = [
        :nqt_in_academic_year_after_itt,
        :current_school_id,
        :induction_completed,
        :school_somewhere_else,
        :employed_as_supply_teacher,
        :has_entire_term_contract,
        :employed_directly,
        :subject_to_formal_performance_action,
        :subject_to_disciplinary_action,
        :qualification,
        :eligible_itt_subject,
        :teaching_subject_now,
        :itt_academic_year
      ].freeze
      AMENDABLE_ATTRIBUTES = [:award_amount].freeze
      ATTRIBUTE_DEPENDENCIES = {
        "employed_as_supply_teacher" => ["has_entire_term_contract", "employed_directly"],
        "qualification" => ["eligible_itt_subject", "teaching_subject_now"],
        "eligible_itt_subject" => ["teaching_subject_now"],
        "itt_academic_year" => ["eligible_itt_subject"]
      }.freeze

      IGNORED_ATTRIBUTES = [
        "eligible_degree_subject"
      ]

      self.table_name = "early_career_payments_eligibilities"

      FIRST_ITT_AY = "2016/2017"
      LAST_POLICY_YEAR = "2024/2025"

      # Generates an object similar to
      # {
      #   <AcademicYear:0x00007f7d87429238 @start_year=2020, @end_year=2021> => "2020/2021",
      #   <AcademicYear:0x00007f7d87429210 @start_year=2021, @end_year=2022> => "2021/2022",
      #   <AcademicYear:0x00007f7d87428c98 @start_year=nil, @end_year=nil> => "None"
      # }
      # Note: ECP policy began in academic year 2021/22 so the persisted options
      # should include 2016/17 onward.
      # In test environment the journey configuration record may not exist.
      # This can't be dynamic on Journeys::Configuration current_academic_year because changing the year means the 5 year window changes
      # and the enums would be stale until after a server restart.
      # Make all valid ITT values based on the last known policy year.
      ITT_ACADEMIC_YEARS =
        (AcademicYear.new(FIRST_ITT_AY)...AcademicYear.new(LAST_POLICY_YEAR)).each_with_object({}) do |year, hsh|
          hsh[year] = AcademicYear::Type.new.serialize(year)
        end.merge({AcademicYear.new => AcademicYear::Type.new.serialize(AcademicYear.new)})

      enum itt_academic_year: ITT_ACADEMIC_YEARS

      enum qualification: {
        postgraduate_itt: 0,
        undergraduate_itt: 1,
        assessment_only: 2,
        overseas_recognition: 3
      }

      enum eligible_itt_subject: {
        chemistry: 0,
        foreign_languages: 1,
        mathematics: 2,
        physics: 3,
        none_of_the_above: 4,
        computing: 5
      }, _prefix: :itt_subject

      def self.max_award_amount_in_pounds
        Policies::EarlyCareerPayments::AwardAmountCalculator.max_award_amount_in_pounds
      end

      has_one :claim, as: :eligibility, inverse_of: :eligibility
      belongs_to :current_school, optional: true, class_name: "School"

      validates :current_school, on: [:"correct-school"], presence: {message: "Select the school you teach at or choose somewhere else"}, unless: :school_somewhere_else?
      validates :employed_directly, on: [:"employed-directly", :submit], inclusion: {in: [true, false], message: "Select yes if you are directly employed by your school"}, if: :employed_as_supply_teacher?
      validates :qualification, on: [:qualification, :submit], presence: {message: "Select the route you took into teaching"}
      validates :eligible_itt_subject, on: [:"eligible-itt-subject", :submit], presence: {message: ->(object, data) { I18n.t("activerecord.errors.models.early_career_payments_eligibilities.attributes.eligible_itt_subject.blank.qualification") }}
      validates :teaching_subject_now, on: [:"teaching-subject-now", :submit], inclusion: {in: [true, false], message: "Select yes if you spend at least half of your contracted hours teaching eligible subjects"}
      validates :itt_academic_year, on: [:"itt-year", :submit], presence: {message: ->(object, data) { I18n.t("activerecord.errors.models.early_career_payments_eligibilities.attributes.itt_academic_year.blank.qualification.#{object.qualification}") }}
      validates :award_amount, on: [:submit], presence: {message: "Enter an award amount"}
      validates_numericality_of :award_amount, message: "Enter a valid monetary amount", allow_nil: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 7500
      validates :award_amount, on: :amendment, award_range: {max: max_award_amount_in_pounds}

      before_save :set_qualification_if_trainee_teacher, if: :nqt_in_academic_year_after_itt_changed?

      delegate :name, to: :current_school, prefix: true, allow_nil: true

      def policy
        Policies::EarlyCareerPayments
      end

      # Rescues from errors for assignments coming from LUP-only fields
      # eg. `claim.eligibility.eligible_degree_subject = true` will get ignored
      def assign_attributes(*args, **kwargs)
        super
      rescue ActiveRecord::UnknownAttributeError
        all_attributes_ignored = (args.first.keys - IGNORED_ATTRIBUTES).empty?
        raise unless all_attributes_ignored
      end

      def eligible_later_year
        # This covers the case for *the other policy* (LUP) which has *no* ITT academic year set for a trainee teacher
        # but this method will still be called and needs to run without error
        if itt_academic_year.blank?
          nil
        else
          JourneySubjectEligibilityChecker.new(claim_year: claim_year, itt_year: itt_academic_year).next_eligible_claim_year_after_current_claim_year(CurrentClaim.new(claims: [claim]))
        end
      end

      def award_amount
        super || BigDecimal(calculate_award_amount || 0)
      end

      def first_eligible_itt_academic_year
        JourneySubjectEligibilityChecker.first_eligible_itt_year_for_subject(policy: policy, claim_year: claim_year, subject_symbol: eligible_itt_subject.to_sym)
      end

      def reset_dependent_answers(reset_attrs = [])
        attrs = ineligible? ? changed.concat(reset_attrs) : changed

        dependencies = ATTRIBUTE_DEPENDENCIES.dup

        # If some data was derived from DQT we do not want to reset these.
        if claim.qualifications_details_check
          dependencies.delete("qualification")
          dependencies.delete("eligible_itt_subject")
          dependencies.delete("itt_academic_year")
        end

        dependencies.each do |attribute_name, dependent_attribute_names|
          dependent_attribute_names.each do |dependent_attribute_name|
            write_attribute(dependent_attribute_name, nil) if attrs.include?(attribute_name)
          end
        end
      end

      def submit!
        self.award_amount = award_amount
        save!
      end

      def induction_not_completed?
        !induction_completed.nil? && !induction_completed?
      end

      def ecp_only_school?
        Policies::EarlyCareerPayments::SchoolEligibility.new(claim.eligibility.current_school).eligible? &&
          !Policies::LevellingUpPremiumPayments::SchoolEligibility.new(claim.eligibility.current_school).eligible?
      end

      def set_qualifications_from_dqt_record
        self.attributes = {
          itt_academic_year: claim.qualifications_details_check ? (claim.dqt_teacher_record&.itt_academic_year_for_claim || itt_academic_year) : nil,
          eligible_itt_subject: claim.qualifications_details_check ? (claim.dqt_teacher_record&.eligible_itt_subject_for_claim || eligible_itt_subject) : nil,
          qualification: claim.qualifications_details_check ? (claim.dqt_teacher_record&.route_into_teaching || qualification) : nil
        }
      end

      private

      def calculate_award_amount
        return 0 if eligible_itt_subject.blank?

        args = {policy_year: claim_year, itt_year: itt_academic_year, subject_symbol: eligible_itt_subject.to_sym, school: current_school}

        if args.values.any?(&:blank?)
          0
        else
          Policies::EarlyCareerPayments::AwardAmountCalculator.new(**args).amount_in_pounds
        end
      end

      def specific_eligible_now_attributes?
        induction_completed? && itt_subject_eligible_now?
      end

      def itt_subject_eligible_now?
        itt_subject = eligible_itt_subject # attribute name implies eligibility which isn't always the case
        return false if itt_subject.blank?
        return false if itt_subject_none_of_the_above?

        itt_subject_checker = JourneySubjectEligibilityChecker.new(claim_year: claim_year, itt_year: itt_academic_year)
        itt_subject.to_sym.in?(itt_subject_checker.current_subject_symbols(policy))
      end

      def specific_ineligible_attributes?
        trainee_teacher? || (induction_not_completed? && !ecp_only_school?) || itt_subject_ineligible_now_and_in_the_future?
      end

      def itt_subject_ineligible_now_and_in_the_future?
        itt_subject = eligible_itt_subject # attribute name implies eligibility which isn't always the case
        return false if itt_subject.blank?
        return true if itt_subject_none_of_the_above?

        itt_subject_checker = JourneySubjectEligibilityChecker.new(claim_year: claim_year, itt_year: itt_academic_year)
        !itt_subject.to_sym.in?(itt_subject_checker.current_and_future_subject_symbols(policy))
      end

      def specific_eligible_later_attributes?
        newly_qualified_teacher? && ((induction_not_completed? && ecp_only_school?) || (!itt_subject_eligible_now? && itt_subject_eligible_later?))
      end

      def itt_subject_eligible_later?
        itt_subject = eligible_itt_subject # attribute name implies eligibility which isn't always the case
        return false if itt_subject.blank?
        return false if itt_subject_none_of_the_above?

        itt_subject_checker = JourneySubjectEligibilityChecker.new(claim_year: claim_year, itt_year: itt_academic_year)
        itt_subject.to_sym.in?(itt_subject_checker.future_subject_symbols(policy))
      end

      def itt_subject_ineligible?
        return false if claim_year.blank?

        itt_subject_other_than_those_eligible_now_or_in_the_future?
      end

      def itt_subject_other_than_those_eligible_now_or_in_the_future?
        itt_subject = eligible_itt_subject # attribute name implies eligibility which isn't always the case
        return false if itt_subject.blank?

        args = {claim_year: claim_year, itt_year: itt_academic_year}

        if args.any?(&:blank?)
          # can still rule some out
          itt_subject_none_of_the_above?
        else
          itt_subject_checker = JourneySubjectEligibilityChecker.new(**args)
          itt_subject_symbol = itt_subject.to_sym
          !itt_subject_symbol.in?(itt_subject_checker.current_and_future_subject_symbols(policy))
        end
      end

      def set_qualification_if_trainee_teacher
        return unless trainee_teacher?

        self.qualification = :postgraduate_itt
      end
    end
  end
end
