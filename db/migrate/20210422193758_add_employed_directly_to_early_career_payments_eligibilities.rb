class AddEmployedDirectlyToEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :early_career_payments_eligibilities, :employed_directly, :boolean
  end
end
