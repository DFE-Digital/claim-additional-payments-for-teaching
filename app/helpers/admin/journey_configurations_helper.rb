module Admin
  module JourneyConfigurationsHelper
    def options_for_academic_year
      (0..3).map { |relative_year| AcademicYear.current + relative_year }
    end

    def targeted_retention_incentive_awards_last_updated_at
      Policies::TargetedRetentionIncentivePayments::Award.last_updated_at(journey_configuration.current_academic_year)
    end

    def targeted_retention_incentive_awards_academic_years
      Policies::TargetedRetentionIncentivePayments::Award.distinct_academic_years
    end
  end
end
