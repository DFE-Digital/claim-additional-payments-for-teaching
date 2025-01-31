class RenameTablesLupToTri < ActiveRecord::Migration[8.0]
  def change
    rename_table :levelling_up_premium_payments_eligibilities, :targeted_retention_incentive_payments_eligibilities
    rename_table :levelling_up_premium_payments_awards, :targeted_retention_incentive_payments_awards
  end
end
