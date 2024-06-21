class CreatePoliciesRelocationPaymentsEligibilities < ActiveRecord::Migration[7.0]
  def change
    create_table :international_relocation_payments_eligibilities, id: :uuid do |t|
      t.timestamps
    end
  end
end
