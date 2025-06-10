class DropLupTables < ActiveRecord::Migration[8.0]
  def change
    drop_table :levelling_up_premium_payments_awards
    drop_table :levelling_up_premium_payments_eligibilities
  end
end
