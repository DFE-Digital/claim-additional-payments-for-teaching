class AddPostgraduateDoctoralLoanToClaims < ActiveRecord::Migration[6.0]
  def change
    add_column :claims, :postgraduate_doctoral_loan, :boolean
  end
end
