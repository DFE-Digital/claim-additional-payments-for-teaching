# frozen_string_literal: true

class DayMonthYearDateValidator
  def validate(record, attribute = "day_month_year_date")
    @record = record

    record.errors.add(attribute, "Enter a valid date") unless valid?
  end

private

  def valid?
    return true unless @record.day.present? && @record.month.present? && @record.year.present?

    day = @record.day.to_i
    month = @record.month.to_i
    year = @record.year.to_i

    return false unless [day, month, year].all?(&:positive?)

    Date.valid_date?(year, month, day)
  rescue ArgumentError
    false
  end
end
