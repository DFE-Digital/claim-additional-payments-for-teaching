class ProviderVerificationCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :further_education_payments_eligibilities,
      :provider_verification_building_construction_courses,
      :jsonb,
      default: []

    add_column :further_education_payments_eligibilities,
      :provider_verification_chemistry_courses,
      :jsonb,
      default: []

    add_column :further_education_payments_eligibilities,
      :provider_verification_computing_courses,
      :jsonb,
      default: []

    add_column :further_education_payments_eligibilities,
      :provider_verification_early_years_courses,
      :jsonb,
      default: []

    add_column :further_education_payments_eligibilities,
      :provider_verification_engineering_manufacturing_courses,
      :jsonb,
      default: []

    add_column :further_education_payments_eligibilities,
      :provider_verification_maths_courses,
      :jsonb,
      default: []

    add_column :further_education_payments_eligibilities,
      :provider_verification_physics_courses,
      :jsonb,
      default: []
  end
end
