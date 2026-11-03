class AddFeMiddleAwardAmount < ActiveRecord::Migration[8.1]
  def change
    add_column :eligible_fe_providers, :middle_award_amount, :decimal, precision: 7, scale: 2
  end
end
