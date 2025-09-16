class AddEoiLimitToEligibleEyProviders < ActiveRecord::Migration[8.0]
  def change
    add_column :eligible_ey_providers, :max_claims, :integer, default: 0, null: false
  end
end
