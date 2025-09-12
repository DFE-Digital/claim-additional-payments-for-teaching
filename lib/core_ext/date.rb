module CoreExt
  module Date
    def last_day_of_the_month?
      day == end_of_month.day
    end

    def term
      autumn_start = self.class.new(year, 9, 1)
      autumn_end = self.class.new(year, 12, 31)
      spring_start = self.class.new(year, 1, 1)
      spring_end = self.class.new(year, 4, 12)
      summer_start = self.class.new(year, 4, 13)
      summer_end = self.class.new(year, 8, 31)

      case self
      when spring_start..spring_end then "spring"
      when summer_start..summer_end then "summer"
      when autumn_start..autumn_end then "autumn"
      else raise "Unexpected date"
      end
    end
  end
end

Date.include CoreExt::Date
Time.include CoreExt::Date
