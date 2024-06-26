class AddNationalityToInternationalRelocationPaymentsEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :international_relocation_payments_eligibilities, :nationality, :string
  end
end
