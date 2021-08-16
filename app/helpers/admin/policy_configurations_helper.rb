module Admin
  module PolicyConfigurationsHelper
    def options_for_academic_year
      (0..3).map { |relative_year| AcademicYear.current + relative_year }
    end
  end
end
