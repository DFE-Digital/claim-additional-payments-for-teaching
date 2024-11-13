class FeProvidersUnique < ActiveRecord::Migration[7.0]
  def change
    remove_index :eligible_fe_providers, [:academic_year, :ukprn]
    add_index :eligible_fe_providers, [:academic_year, :ukprn], unique: true
  end
end
