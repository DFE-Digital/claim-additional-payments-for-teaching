class AddPostgraduateMastersLoanToClaims < ActiveRecord::Migration[6.0]
  def change
    add_column :claims, :postgraduate_masters_loan, :boolean
  end
end
