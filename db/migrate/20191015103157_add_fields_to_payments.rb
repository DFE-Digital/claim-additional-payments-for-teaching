class AddFieldsToPayments < ActiveRecord::Migration[5.2]
  def change
    add_column :payments, :payroll_reference, :string
    add_column :payments, :gross_value, :decimal, precision: 7, scale: 2
    add_column :payments, :national_insurance, :decimal, precision: 7, scale: 2
    add_column :payments, :employers_national_insurance, :decimal, precision: 7, scale: 2
    add_column :payments, :student_loan_repayment, :decimal, precision: 7, scale: 2
    add_column :payments, :tax, :decimal, precision: 7, scale: 2
    add_column :payments, :net_pay, :decimal, precision: 7, scale: 2
  end
end
