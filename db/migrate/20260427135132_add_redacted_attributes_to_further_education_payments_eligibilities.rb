class AddRedactedAttributesToFurtherEducationPaymentsEligibilities < ActiveRecord::Migration[8.1]
  def change
    add_column(
      :further_education_payments_eligibilities,
      :redacted_attributes,
      :jsonb,
      default: {}
    )
  end
end
