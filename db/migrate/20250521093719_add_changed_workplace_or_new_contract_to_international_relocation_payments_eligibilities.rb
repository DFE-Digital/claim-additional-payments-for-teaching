class AddChangedWorkplaceOrNewContractToInternationalRelocationPaymentsEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column :international_relocation_payments_eligibilities, :changed_workplace_or_new_contract, :boolean
  end
end
