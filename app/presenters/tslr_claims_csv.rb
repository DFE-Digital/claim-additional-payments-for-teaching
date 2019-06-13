require "csv"

class TslrClaimsCsv
  attr_accessor :claims

  FIELDS = [
    :reference,
    :qts_award_year,
    :claim_school_name,
    :employment_status,
    :current_school_name,
    :full_name,
    :address_line_1,
    :address_line_2,
    :address_line_3,
    :address_line_4,
    :postcode,
    :date_of_birth,
    :teacher_reference_number,
    :national_insurance_number,
    :email_address,
    :mostly_teaching_eligible_subjects,
    :bank_sort_code,
    :bank_account_number,
    :student_loan_repayment_amount,
  ].freeze

  def initialize(claims)
    self.claims = claims
  end

  def csv_headers
    FIELDS.map { |h| header_string_for_field(h) }
  end

  private

  def header_string_for_field(header)
    I18n.t("tslr.csv_headers.#{header}")
  end
end
