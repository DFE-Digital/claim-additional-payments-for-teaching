class AddVerificationToFurtherEducationPaymentsEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :further_education_payments_eligibilities, :verification, :jsonb, default: {}
  end
end
