class AddEmploymentDetailsToInternationalRelocationPaymentsEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :international_relocation_payments_eligibilities, :school_headteacher_name, :string
    add_column :international_relocation_payments_eligibilities, :school_name, :string
    add_column :international_relocation_payments_eligibilities, :school_address_line_1, :string
    add_column :international_relocation_payments_eligibilities, :school_address_line_2, :string
    add_column :international_relocation_payments_eligibilities, :school_city, :string
    add_column :international_relocation_payments_eligibilities, :school_postcode, :string
  end
end
