# Include this module in a journey form to handle date of birth multipart
# parameters and validations.
#
# Usage
# ```
#    class MyJourneyForm < Form
#      include DateOfBirth
#      self.date_of_birth_field = :date_of_birth
# ```

module DateOfBirth
  extend ActiveSupport::Concern

  InvalidDate = Struct.new(:day, :month, :year, keyword_init: true) do
    def future?
      false
    end
  end

  included do
    attribute :day
    attribute :month
    attribute :year
    validate :date_of_birth_criteria
    after_initialize :assign_date_attributes
  end

  class_methods do
    def date_of_birth_field=(field_name)
      define_method(:date_of_birth_field) { field_name }

      define_method("#{field_name}=") do |value|
        instance_variable_set("@#{field_name}", value)
      end

      define_method(field_name) do
        date_hash = {year:, month:, day:}
        date_args = date_hash.values.map(&:to_i)

        Date.valid_date?(*date_args) ? Date.new(*date_args) : InvalidDate.new(date_hash)
      end

      define_method(:dob_param_conversion) do
        {
          "#{date_of_birth_field}(3i)" => "day",
          "#{date_of_birth_field}(2i)" => "month",
          "#{date_of_birth_field}(1i)" => "year"
        }
      end
    end
  end

  private

  def permitted_params
    @permitted_params ||= params.fetch(:claim, {})
      .permit(*attributes, *dob_param_conversion.keys)
      .transform_keys { |key| dob_param_conversion.has_key?(key) ? dob_param_conversion[key] : key }
  end

  def assign_date_attributes
    self.day = permitted_params.fetch(:day, answers.public_send(date_of_birth_field)&.day)
    self.month = permitted_params.fetch(:month, answers.public_send(date_of_birth_field)&.month)
    self.year = permitted_params.fetch(:year, answers.public_send(date_of_birth_field)&.year)
  end

  def date_of_birth_criteria
    if public_send(date_of_birth_field).future?
      errors.add(:"#{date_of_birth_field}", date_of_birth_future_error_message)
    elsif number_of_date_components.between?(1, 2)
      errors.add(:"#{date_of_birth_field}", date_of_birth_missing_components_error_message)
    elsif number_of_date_components.zero?
      errors.add(:"#{date_of_birth_field}", date_of_birth_blank_error_message)
    elsif public_send(date_of_birth_field).is_a?(InvalidDate)
      errors.add(:"#{date_of_birth_field}", date_of_birth_invalid_error_message)
    elsif public_send(date_of_birth_field).year < 1000
      errors.add(:"#{date_of_birth_field}", date_of_birth_three_digit_year_error_message)
    elsif public_send(date_of_birth_field).year <= 1900
      errors.add(:"#{date_of_birth_field}", date_of_birth_before_1900_error_message)
    end

    errors[:"#{date_of_birth_field}"].empty?
  end

  def number_of_date_components
    [day, month, year].compact_blank.size
  end

  def date_of_birth_future_error_message
    "Date of birth must be in the past"
  end

  def date_of_birth_missing_components_error_message
    "Date of birth must include a day, month and year in the correct format, for example 01 01 1980"
  end

  def date_of_birth_blank_error_message
    "Enter your date of birth"
  end

  def date_of_birth_invalid_error_message
    "Enter a date of birth in the correct format"
  end

  def date_of_birth_three_digit_year_error_message
    "Year must include 4 numbers"
  end

  def date_of_birth_before_1900_error_message
    "Year must be after 1900"
  end
end
