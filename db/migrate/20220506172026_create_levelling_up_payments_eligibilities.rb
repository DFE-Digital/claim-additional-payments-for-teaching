class CreateLevellingUpPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    create_table :levelling_up_payments_eligibilities, id: :uuid do |t|
      t.timestamps
    end
  end
end
