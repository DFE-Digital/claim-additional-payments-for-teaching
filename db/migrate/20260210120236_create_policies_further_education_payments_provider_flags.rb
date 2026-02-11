class CreatePoliciesFurtherEducationPaymentsProviderFlags < ActiveRecord::Migration[8.1]
  def change
    create_table :further_education_payments_provider_flags, id: :uuid do |t|
      t.integer :ukprn, null: false
      t.string :academic_year, null: false
      t.string :reason, null: false

      t.timestamps
    end
  end
end
