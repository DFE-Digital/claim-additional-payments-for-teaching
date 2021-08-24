# Used to model an academic year, which is normally dispayed in the format
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
      start_of_autumn_term = Date.new(date.year, 9, 1)
      if date < start_of_autumn_term
        new(date.year - 1)
      else
        new(date.year)
      end
    end
  end

  def initialize(start_year = nil)
    self.years = start_year
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

  private

  def years=(start_year)
    if start_year.nil?
      @start_year = @end_year = nil
    else
      @start_year = start_year.to_s.split("/").first.to_i
      @end_year = self.start_year + 1
    end
  end
end
