class RemoveAcademicYearFromFeProviderFlags < ActiveRecord::Migration[8.1]
  def change
    remove_column :further_education_payments_provider_flags, :academic_year, :string
  end
end
