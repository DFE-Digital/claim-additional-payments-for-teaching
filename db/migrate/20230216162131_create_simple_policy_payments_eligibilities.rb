class CreateSimplePolicyPaymentsEligibilities < ActiveRecord::Migration[6.1]
  def change
    create_table :simple_policy_payments_eligibilities, id: :uuid do |t|
      t.references :current_school, type: :uuid, foreign_key: {to_table: :schools}, index: true
      t.timestamps
    end
  end
end
