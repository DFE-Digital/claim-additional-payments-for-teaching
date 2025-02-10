module Admin
  module JourneyConfigurationsHelper
    def options_for_academic_year
      (0..3).map { |relative_year| AcademicYear.current + relative_year }
    end

    def lupp_awards_last_updated_at
      Policies::LevellingUpPremiumPayments::Award.last_updated_at(journey_configuration.current_academic_year)
    end

    def lupp_awards_academic_years
      Policies::LevellingUpPremiumPayments::Award.distinct_academic_years
    end
  end
end
