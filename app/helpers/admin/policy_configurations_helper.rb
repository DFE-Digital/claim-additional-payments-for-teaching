module Admin
  module PolicyConfigurationsHelper
    def start_of_autumn_term
      Date.new(Date.today.year, 9, 1)
    end

    def options_for_academic_year
      [current_academic_year, next_academic_year]
    end

    def current_academic_year
      if Date.today < start_of_autumn_term
        [(Date.today.year - 1), Date.today.year].join("/")
      else
        [Date.today.year, (Date.today.year + 1)].join("/")
      end
    end

    def next_academic_year
      start_year = current_academic_year.split("/").last.to_i
      end_year = start_year + 1

      [start_year, end_year].join("/")
    end
  end
end
