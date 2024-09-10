class AddFlaggedAsDuplicateToFurtherEducationPaymentsEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :further_education_payments_eligibilities,
      :flagged_as_duplicate,
      :boolean,
      default: false
  end
end
