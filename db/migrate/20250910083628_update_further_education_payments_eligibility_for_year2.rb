class UpdateFurtherEducationPaymentsEligibilityForYear2 < ActiveRecord::Migration[8.0]
  def change
    # Add conditional field for variable hours contracts (next term hours)
    # This field doesn't exist yet, so add it
    add_column :further_education_payments_eligibilities, :provider_verification_teaching_hours_per_week_next_term, :string

    # The following fields already exist and can handle year 2 requirements:
    # - provider_verification_teaching_qualification (string) - can handle new options
    # - provider_verification_contract_type (string) - already has the right values
    # - provider_verification_contract_covers_full_academic_year (boolean) - already exists
    # - provider_verification_performance_measures (boolean) - already exists
    # - provider_verification_disciplinary_action (boolean) - already exists
    # - provider_verification_teaching_hours_per_week (string) - already exists

    # Add indexes for performance on key lookup fields
    add_index :further_education_payments_eligibilities, :provider_verification_teaching_qualification, name: "idx_fe_provider_teaching_qualification"
    add_index :further_education_payments_eligibilities, :provider_verification_contract_type, name: "idx_fe_provider_contract_type"
  end
end
