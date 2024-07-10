class AddStateFundedSecondarySchoolToInternationalRelocationPaymentsEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :international_relocation_payments_eligibilities, :state_funded_secondary_school, :boolean
  end
end
