# Used to model an academic year, which is normally displayed in the format
# "YYYY/YYYY". Supports comparison and basic arithmetic operations.
#
# Can be initialised both with a single start year, or the academic year as a
# string. For example:
#
#   AcademicYear.new(2014).to_s        #=> "2014/2015"
#   AcademicYear.new("2014/2015").to_s #=> "2014/2015"
#
# It also supports being displayed in a user-friendly format:
#
#   AcademicYear.new("2014/2015").to_s(:long) #=> "2014 to 2015"
class AcademicYear
  include Comparable

  ACADEMIC_YEAR_REGEXP = /\A20\d{2}\/20\d{2}\z/

  AUTUMN_TERM_START_MONTH = 9
  AUTUMN_TERM_START_DAY = 1

  attr_reader :start_year, :end_year

  # Defines a custom ActiveRecord::Type for AcademicYear that means we can
  # define attributes on our models that save and return AcademicYear objects.
  # See the Claim#academic_year attribute.
  class Type < ActiveRecord::Type::Value
    def serialize(value)
      return nil if value.nil?

      value.to_s
    end

    def cast(value)
      return nil if value.nil?

      value = nil if value == "None"

      AcademicYear.new(value)
    end
  end

  class << self
    # Returns the current academic year, based on September 1st being the start
    # of the year.
    def current
      self.for(Date.today)
    end

    def next
      current + 1
    end

    # Returns the academic year for a given date, based on September 1st being
    # the start of the year.
    def for(date)
      return if date.nil?

      start_of_autumn_term = Date.new(
        date.year,
        AUTUMN_TERM_START_MONTH,
        AUTUMN_TERM_START_DAY
      )

      if date < start_of_autumn_term
        new(date.year - 1)
      else
        new(date.year)
      end
    end

    def wrap(value)
      return value if value.is_a? AcademicYear

      new(value)
    end
  end

  def initialize(year_or_academic_year_or_string = nil)
    if year_or_academic_year_or_string.nil?
      # would have thought this should be an error really but maintaining interface for now
      @start_year = @end_year = nil
    elsif year_or_academic_year_or_string.is_a? Integer
      @start_year = year_or_academic_year_or_string
      @end_year = @start_year + 1
    elsif year_or_academic_year_or_string.is_a? Hash
      @start_year = year_or_academic_year_or_string.with_indifferent_access[:start_year]
      @end_year = year_or_academic_year_or_string.with_indifferent_access[:end_year]
    elsif year_or_academic_year_or_string.is_a? AcademicYear
      @start_year = year_or_academic_year_or_string.start_year
      @end_year = year_or_academic_year_or_string.end_year
    elsif year_or_academic_year_or_string.match?(/^\d{4}$/)
      @start_year = year_or_academic_year_or_string.to_i
      @end_year = @start_year + 1
    elsif /^(?<start_year_string>\d{4})\/(?<end_year_string>\d{4})$/ =~ year_or_academic_year_or_string
      start_year_i, end_year_i = start_year_string.to_i, end_year_string.to_i

      if end_year_i == start_year_i + 1
        @start_year = start_year_i
        @end_year = end_year_i
      else
        raise "#{year_or_academic_year_or_string} are not increasing consecutive years"
      end
    end
  end

  def eql?(other)
    to_s == other.to_s
  end

  def to_s(format = :default)
    return "None" if [start_year, end_year].include? nil

    if format == :long
      "#{start_year} to #{end_year}"
    else
      "#{start_year}/#{end_year}"
    end
  end

  def ==(other)
    to_s == other.to_s
  end

  # allows this class to be used in a Range
  def succ
    AcademicYear.new(@start_year + 1)
  end

  def <=>(other)
    start_year <=> other.start_year
  end

  # Generates an Integer hash value for the object.
  #
  # Used primarily by the `Hash` class to determine if two objects reference the
  # same hash key, but also used by the RSpec change matcher when doing
  # comparison of nested objects.
  def hash
    [self.class, start_year].hash
  end

  def -(other)
    AcademicYear.new(start_year - other)
  end

  def +(other)
    AcademicYear.new(start_year + other)
  end

  def start_of_autumn_term
    Date.new(start_year, AUTUMN_TERM_START_MONTH, AUTUMN_TERM_START_DAY)
  end
end
