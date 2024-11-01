class CreateRiskIndicators < ActiveRecord::Migration[7.0]
  def change
    create_table :risk_indicators, id: :uuid do |t|
      t.string :field, null: false
      t.string :value, null: false

      t.index %i[field value], unique: true

      t.timestamps
    end
  end
end
