class AddClaimantDeclaration < ActiveRecord::Migration[8.0]
  def change
    add_column :claims, :claimant_declaration, :boolean
  end
end
