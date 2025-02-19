module Policies
  module TargetedRetentionIncentivePayments
    # there'll be a better way of doing this
    ELIGIBLE_ACADEMIC_YEARS = [
      AcademicYear.new("2017/2018"),
      AcademicYear.new("2018/2019"),
      AcademicYear.new("2019/2020"),
      AcademicYear.new("2020/2021"),
      AcademicYear.new("2021/2022"),
      AcademicYear.new("2022/2023"),
      AcademicYear.new("2023/2024")
    ]

    # Checks whether an academic year is eligible for Targeted Retention Incentive. An eligible academic year
    # is necessary but not sufficient to award Targeted Retention Incentive.
    #
    # This class would only need to change if the set of eligible years change.
    #
    # For postgrads we're talking about the start year, for undergrads it's the end year
    class AcademicYearEligibility
      def initialize(academic_year)
        raise "nil academic year" if academic_year.nil?

        @academic_year = academic_year
      end

      def eligible?
        @academic_year.in? ELIGIBLE_ACADEMIC_YEARS
      end
    end
  end
end
