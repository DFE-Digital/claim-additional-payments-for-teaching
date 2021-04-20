class AddHasEntireTermContractToEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :early_career_payments_eligibilities, :has_entire_term_contract, :boolean
  end
end
