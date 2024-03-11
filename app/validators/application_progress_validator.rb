class ApplicationProgressValidator
  DATE_PARAMS = %i[
    initial_checks_completed_at
    home_office_checks_completed_at
    school_checks_completed_at
    banking_approval_completed_at
    payment_confirmation_completed_at
    rejection_completed_at
  ].freeze

  def initialize(progress, params)
    @progress = progress
    @params = params
  end

  def valid?
    process_date_params
    process_non_date_params

    date_errors = @progress.errors.dup
    model_valid = @progress.valid?
    @progress.errors.merge!(date_errors)

    model_valid && @progress.errors.empty?
  end

private

  def process_date_params
    DATE_PARAMS.each { |date_param| process_date_param(date_param) }
  end

  def process_date_param(date_param)
    day, month, year = extract_date_components(date_param)
    return if year.blank? && month.blank? && day.blank?

    field_date = parse_date(year, month, day)

    return invalid_date(date_param, day, month, year) unless field_date
    return invalid_date_range(date_param, field_date) if date_out_range?(field_date)

    @progress[date_param] = field_date
  end

  def extract_date_components(date_param)
    [
      @params["#{date_param}(3i)"],
      @params["#{date_param}(2i)"],
      @params["#{date_param}(1i)"],
    ]
  end

  def process_non_date_params
    remaining_params = @params.reject { |param, _| param.start_with?(*DATE_PARAMS.map(&:to_s)) }
    remaining_params.each { |param, value| @progress[param] = value }
  end

  def invalid_date(date_param, day, month, year)
    @progress.errors.add(date_param, "is not a valid date")
    @progress[date_param] = InvalidDate.new(day:, month:, year:)
  end

  def invalid_date_range(date_param, field_date)
    @progress.errors.add(date_param, "out of range")
    @progress[date_param] = field_date
  end

  def date_out_range?(field_date)
    field_date < 12.months.ago || 12.months.from_now < field_date
  end

  def parse_date(year, month, day)
    Date.new(year.to_i, month.to_i, day.to_i)
  rescue StandardError
    nil
  end
end
