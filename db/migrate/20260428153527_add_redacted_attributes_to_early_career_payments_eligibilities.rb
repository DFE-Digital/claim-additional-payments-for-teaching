class AddRedactedAttributesToEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[8.1]
  def change
    add_column(
      :early_career_payments_eligibilities,
      :redacted_attributes,
      :jsonb,
      default: {}
    )
  end
end
