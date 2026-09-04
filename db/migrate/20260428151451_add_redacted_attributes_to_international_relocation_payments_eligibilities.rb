class AddRedactedAttributesToInternationalRelocationPaymentsEligibilities < ActiveRecord::Migration[8.1]
  def change
    add_column(
      :international_relocation_payments_eligibilities,
      :redacted_attributes,
      :jsonb,
      default: {}
    )
  end
end
