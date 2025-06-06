class AddIrpBreaksInEmployment < ActiveRecord::Migration[8.0]
  def change
    add_column :international_relocation_payments_eligibilities, :breaks_in_employment, :boolean
  end
end
