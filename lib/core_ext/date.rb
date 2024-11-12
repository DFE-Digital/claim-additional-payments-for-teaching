module CoreExt
  module Date
    def last_day_of_the_month?
      day == end_of_month.day
    end
  end
end

Date.include CoreExt::Date
