class TeachersPensionsService < ApplicationRecord
  self.table_name = "teachers_pensions_service"

  # Number of previous FULL months considered
  RECENT_TPS_FULL_MONTHS = 2.months

  validates :teacher_reference_number, uniqueness: {scope: :start_date}

  # NOTE: `teachers_pensions_service` table stores the start_date/end_date as DateTime and NOT a Date.
  # E.g. end of August is stored as 2023-08-30 23:00:00 UTC.
  # Be careful with boundary comparisons and time zones.

  scope :by_teacher_reference_number, ->(teacher_reference_number) { where(teacher_reference_number: teacher_reference_number) }
  scope :between_claim_dates, ->(start_date, end_date) { where(start_date: start_date..end_date) }
  scope :claim_dates_interval, ->(latest_start_date, earliest_end_date) { where(start_date: ..latest_start_date).or(where(end_date: earliest_end_date..)) }
  scope :ended_on_or_after, ->(earliest_end_date) { where(end_date: earliest_end_date..) }
  scope :employed_between, ->(start_date, end_date) { where(end_date: start_date..).and(where(start_date: ..end_date)) }

  def self.recent_tps_school(claim_date:, teacher_reference_number:)
    earliest_end_date = (claim_date - RECENT_TPS_FULL_MONTHS).beginning_of_month

    tps_record = where(teacher_reference_number: teacher_reference_number)
      .ended_on_or_after(earliest_end_date)
      .order(end_date: :desc)
      .limit(1)
      .first

    return nil unless tps_record&.school_urn

    school_for_tps_record(tps_record)
  end

  def self.tps_school_for_student_loan_in_previous_financial_year(teacher_reference_number:)
    previous_academic_year = Policies::StudentLoans.current_academic_year - 1
    start_of_previous_financial_year = Date.new(previous_academic_year.start_year, 4, 6)
    end_of_previous_financial_year = Date.new(Policies::StudentLoans.current_academic_year.start_year, 4, 5)

    tps_records = where(teacher_reference_number: teacher_reference_number)
      .employed_between(start_of_previous_financial_year, end_of_previous_financial_year)
      .order(end_date: :desc)

    # No TPS records
    return nil if tps_records.empty?

    # Ideally - Most recent student loan eligible school
    tps_records.each do |tps_record|
      school = school_for_tps_record(tps_record)
      return school if school&.eligible_for_student_loans_as_claim_school?
    end

    # Fallback - Most recent school but still suggest it
    school_for_tps_record(tps_records.first)
  end

  def self.school_for_tps_record(tps_record)
    # The TPS data is labelled 'URN' but is actually the DfE establishment number
    School.open.joins(:local_authority).find_by(establishment_number: tps_record.school_urn, local_authority: {code: tps_record.la_urn})
  end
end
