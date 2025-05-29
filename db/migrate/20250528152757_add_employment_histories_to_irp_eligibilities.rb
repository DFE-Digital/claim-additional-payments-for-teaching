class AddEmploymentHistoriesToIrpEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :international_relocation_payments_eligibilities,
      :employment_histories,
      :jsonb,
      default: []
    )
  end
end
