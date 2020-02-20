require "academic_year"

module Admin
  module PolicyConfigurationsHelper
    def options_for_academic_year
      [AcademicYear.current, (AcademicYear.current + 1)]
    end
  end
end
