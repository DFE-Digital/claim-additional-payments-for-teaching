module Policies
  module EarlyCareerPayments
    class DqtRecord
      include Dqt::Matchers::General
      include Dqt::Matchers::EarlyCareerPayments

      delegate(
        :qts_award_date,
        :itt_subjects,
        :itt_subject_codes,
        :itt_start_date,
        :degree_codes,
        :degree_names,
        :qualification_name,
        :induction_start_date,
        :induction_completion_date,
        :induction_status,
        to: :record
      )

      delegate(
        :qualification,
        :itt_academic_year,
        :academic_year,
        :eligible_itt_subject,
        to: :answers
      )

      def initialize(record, answers)
        @record = record
        @answers = answers
      end

      def eligible?
        eligible_subject? &&
          eligible_qualification? &&
          eligible_itt_year? &&
          qts_award_date_after_itt_start_date? &&
          award_due?
      end

      def eligible_induction?
        InductionData.new(itt_year:, induction_status:, induction_start_date:).eligible?
      end

      # TODO: May need to prioritise subject chosen by highest award amount?
      def eligible_itt_subject_for_claim
        year = itt_year || itt_academic_year # The user may have supplied this manually if it was missing from the DQT record

        return :none_of_the_above if itt_subject_groups.empty? || !year

        itt_subject_groups.delete_if do |itt_subject_group|
          EarlyCareerPayments.current_and_future_subject_symbols(
            claim_year: current_academic_year,
            itt_year: year
          ).exclude?(itt_subject_group)
        end.first.to_sym
      rescue # JourneySubjectEligibilityChecker can also raise an exception if itt_year is out of eligible range
        :none_of_the_above
      end

      def itt_academic_year_for_claim
        return nil unless academic_date

        year = AcademicYear.for(academic_date)
        eligible_years = JourneySubjectEligibilityChecker.selectable_itt_years_for_claim_year(current_academic_year)
        eligible_years.include?(year) ? year : AcademicYear.new
      end

      def has_no_data_for_claim?
        !eligible_itt_subject_for_claim && !itt_academic_year_for_claim && !route_into_teaching
      end

      private

      attr_reader :record, :answers

      def current_academic_year
        Journeys::AdditionalPaymentsForTeaching.configuration.current_academic_year
      end

      def eligible_itt_year?
        AcademicYear.new(itt_year).eql?(itt_academic_year)
      end

      def award_due?
        award_args = {policy_year: academic_year, itt_year: itt_year, subject_symbol: eligible_itt_subject_group}

        if award_args.values.any?(&:blank?)
          false
        else
          AwardAmountCalculator.award?(**award_args)
        end
      end

      def itt_subject_groups
        [*itt_subject_codes, *degree_codes, *itt_subjects].map do |subject_code|
          ELIGIBLE_JAC_CODES.find { |key, values| subject_code.start_with?(*values) }&.first ||
            ELIGIBLE_HECOS_CODES.find { |key, values| values.include?(subject_code) }&.first ||
            ELIGIBLE_JAC_NAMES.find { |key, values| values.include?(subject_code) }&.first ||
            ELIGIBLE_HECOS_NAMES.find { |key, values| values.include?(subject_code) }&.first
        end.compact.uniq
      end

      def eligible_itt_subject_group
        itt_subject_groups.find { |group| group == eligible_itt_subject&.to_sym }
      end

      def eligible_subject?
        (ELIGIBLE_ITT_SUBJECTS[eligible_itt_subject&.to_sym] & itt_subjects).any?
      end
    end
  end
end
