class AddApplicationRouteToInternationalRelocationPaymentsEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :international_relocation_payments_eligibilities, :application_route, :string
  end
end
