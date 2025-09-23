class AddNotStartedQualificationReasonsToFeEligibility < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_not_started_qualification_reasons,
      :jsonb,
      default: []
    )

    add_column(
      :further_education_payments_eligibilities,
      :provider_verification_not_started_qualification_reason_other,
      :string
    )
  end
end
