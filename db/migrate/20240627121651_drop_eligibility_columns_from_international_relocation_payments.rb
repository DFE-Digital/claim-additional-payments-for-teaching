class DropEligibilityColumnsFromInternationalRelocationPayments < ActiveRecord::Migration[7.0]
  def change
    remove_column :international_relocation_payments_eligibilities, :school_name
    remove_column :international_relocation_payments_eligibilities, :school_address_line_1
    remove_column :international_relocation_payments_eligibilities, :school_address_line_2
    remove_column :international_relocation_payments_eligibilities, :school_city
    remove_column :international_relocation_payments_eligibilities, :school_postcode
  end
end
