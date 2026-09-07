class AddRedactedAttributesToEarlyYearsPaymentsEligibilities < ActiveRecord::Migration[8.1]
  def change
    add_column(
      :early_years_payment_eligibilities,
      :redacted_attributes,
      :jsonb,
      default: {}
    )
  end
end
