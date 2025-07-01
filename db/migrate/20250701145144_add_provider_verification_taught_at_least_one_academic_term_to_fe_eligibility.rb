class AddProviderVerificationTaughtAtLeastOneAcademicTermToFeEligibility < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_taught_at_least_one_academic_term,
      :boolean
    )
  end
end
