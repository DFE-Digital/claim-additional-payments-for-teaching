module Policies
  module EarlyCareerPayments
    class AwardAmountCalculator
      def initialize(policy_year:, itt_year:, subject_symbol:, school:)
        raise_if_subject_symbol_is_not_a_symbol(subject_symbol)
        raise_if_any_nil_values(itt_year, policy_year, school, subject_symbol)

        @policy_year = policy_year
        @itt_year = itt_year
        @subject_symbol = subject_symbol
        @school = school
      end

      def self.award?(policy_year:, itt_year:, subject_symbol:)
        calculator_for_eligible_school = new(policy_year: policy_year, itt_year: itt_year, subject_symbol: subject_symbol, school: OpenStruct.new(eligible_for_early_career_payments?: true, eligible_for_early_career_payments_as_uplift?: true))
        calculator_for_eligible_school.amount_in_pounds.positive?
      end

      # This is used elsewhere for validation when an admin edits a monetary award.
      # The value is hardcoded because this won't change for the remainder of ECP's lifetime
      def self.max_award_amount_in_pounds
        7_500
      end

      def amount_in_pounds
        return 0 unless @school.eligible_for_early_career_payments?
        return 0 unless @policy_year.in?(AcademicYear.new(2021)..AcademicYear.new(2024))

        amount = case @policy_year
                 when AcademicYear.new(2021)
                   case @itt_year
                   when AcademicYear.new(2018)
                     case @subject_symbol
                     when :mathematics
                       if @school.eligible_for_early_career_payments_as_uplift?
                         7_500
                       else
                         5_000
                       end
                     end
                   end
                 when AcademicYear.new(2022)
                   case @itt_year
                   when AcademicYear.new(2019)
                     case @subject_symbol
                     when :mathematics
                       if @school.eligible_for_early_career_payments_as_uplift?
                         7_500
                       else
                         5_000
                       end
                     end
                   when AcademicYear.new(2020)
                     case @subject_symbol
                     when :chemistry, :foreign_languages, :mathematics, :physics
                       if @school.eligible_for_early_career_payments_as_uplift?
                         3_000
                       else
                         2_000
                       end
                     end
                   end
                 when AcademicYear.new(2023)
                   case @itt_year
                   when AcademicYear.new(2018)
                     case @subject_symbol
                     when :mathematics
                       if @school.eligible_for_early_career_payments_as_uplift?
                         7_500
                       else
                         5_000
                       end
                     end
                   when AcademicYear.new(2020)
                     case @subject_symbol
                     when :chemistry, :foreign_languages, :mathematics, :physics
                       if @school.eligible_for_early_career_payments_as_uplift?
                         3_000
                       else
                         2_000
                       end
                     end
                   end
                 when AcademicYear.new(2024)
                   case @itt_year
                   when AcademicYear.new(2019)
                     case @subject_symbol
                     when :mathematics
                       if @school.eligible_for_early_career_payments_as_uplift?
                         7_500
                       else
                         5_000
                       end
                     end
                   when AcademicYear.new(2020)
                     case @subject_symbol
                     when :chemistry, :foreign_languages, :mathematics, :physics
                       if @school.eligible_for_early_career_payments_as_uplift?
                         3_000
                       else
                         2_000
                       end
                     end
                   end
                 end

        amount.nil? ? 0 : amount
      end

      private

      def raise_if_subject_symbol_is_not_a_symbol(subject_symbol)
        raise "#{[subject_symbol]} is not a symbol" unless subject_symbol.is_a?(Symbol)
      end

      def raise_if_any_nil_values(itt_year, policy_year, school, subject_symbol)
        raise_if_nil_policy_year(policy_year)
        raise_if_nil_itt_year(itt_year)
        raise_if_nil_subject_symbol(subject_symbol)
        raise_if_nil_school(school)
      end

      def raise_if_nil_policy_year(value)
        raise "nil policy year" if value.nil?
      end

      def raise_if_nil_itt_year(value)
        raise "nil ITT year" if value.nil?
      end

      def raise_if_nil_subject_symbol(value)
        raise "nil subject symbol" if value.nil?
      end

      def raise_if_nil_school(value)
        raise "nil school" if value.nil?
      end
    end
  end
end
