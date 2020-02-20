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

  class << self
    # Returns the current academic year, based on September 1st being the start
    # of the year.
    def current
      start_of_autumn_term = Date.new(Date.today.year, 9, 1)

      if Date.today < start_of_autumn_term
        new(Date.today.year - 1)
      else
        new(Date.today.year)
      end
    end
  end

  def initialize(start_year)
    @start_year = start_year.to_s.split("/").first.to_i
    @end_year = @start_year + 1
  end

  def to_s(format = :default)
    if format == :long
      "#{start_year} to #{end_year}"
    else
      "#{start_year}/#{end_year}"
    end
  end

  def <=>(other)
    start_year <=> other.start_year
  end

  def -(other)
    AcademicYear.new(start_year - other)
  end

  def +(other)
    AcademicYear.new(start_year + other)
  end
end
