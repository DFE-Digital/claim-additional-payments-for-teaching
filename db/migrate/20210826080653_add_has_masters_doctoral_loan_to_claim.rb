class AddHasMastersDoctoralLoanToClaim < ActiveRecord::Migration[6.0]
  def change
    add_column :claims, :has_masters_doctoral_loan, :boolean
  end
end
