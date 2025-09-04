class RemoveProviderVerificationFields < ActiveRecord::Migration[8.0]
  def change
    remove_column :further_education_payments_eligibilities, :provider_verification_subjects_taught, :boolean
    remove_column :further_education_payments_eligibilities, :provider_verification_actual_subjects_taught, :jsonb
    remove_column :further_education_payments_eligibilities, :provider_verification_building_construction_courses, :jsonb
    remove_column :further_education_payments_eligibilities, :provider_verification_chemistry_courses, :jsonb
    remove_column :further_education_payments_eligibilities, :provider_verification_computing_courses, :jsonb
    remove_column :further_education_payments_eligibilities, :provider_verification_early_years_courses, :jsonb
    remove_column :further_education_payments_eligibilities, :provider_verification_engineering_manufacturing_courses, :jsonb
    remove_column :further_education_payments_eligibilities, :provider_verification_maths_courses, :jsonb
    remove_column :further_education_payments_eligibilities, :provider_verification_physics_courses, :jsonb
  end
end
