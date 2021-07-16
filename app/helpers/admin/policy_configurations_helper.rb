module Admin
  module PolicyConfigurationsHelper
    def options_for_academic_year
      years = 4
      (0..(years - 1)).map { |relative_year| AcademicYear.current + relative_year }
    end
  end
end
