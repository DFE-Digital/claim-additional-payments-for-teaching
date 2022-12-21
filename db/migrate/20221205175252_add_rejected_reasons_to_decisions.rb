class AddRejectedReasonsToDecisions < ActiveRecord::Migration[6.1]
  def change
    add_column :decisions, :rejected_reasons, :jsonb, default: {}
  end
end
