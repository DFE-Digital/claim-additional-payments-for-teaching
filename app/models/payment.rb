class Payment < ApplicationRecord
  has_many :claims
  belongs_to :payroll_run

  validates :award_amount, presence: true

  validates :payroll_reference, :gross_value, :national_insurance, :employers_national_insurance, :tax, :net_pay, :gross_pay, presence: true, on: :upload
  validates :gross_value, :national_insurance, :employers_national_insurance, :student_loan_repayment, :tax, :net_pay, :gross_pay, numericality: true, allow_nil: true

  delegate :first_name, :middle_name, :surname, :national_insurance_number, :payroll_gender, :date_of_birth, :email_address, :address_line_1, :address_line_2, :address_line_3, :address_line_4, :postcode, :has_student_loan, :student_loan_plan, :banking_name, :bank_sort_code, :bank_account_number, :building_society_roll_number, to: :claim

  def claim
    @claim ||= claims.first
  end
end
