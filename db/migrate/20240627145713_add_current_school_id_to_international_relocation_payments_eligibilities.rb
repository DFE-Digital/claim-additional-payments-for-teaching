class AddCurrentSchoolIdToInternationalRelocationPaymentsEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_reference :international_relocation_payments_eligibilities,
      :current_school,
      type: :uuid,
      foreign_key: {to_table: :schools},
      index: {
        name: "index_irb_eligibilities_on_current_school_id"
      }
  end
end
