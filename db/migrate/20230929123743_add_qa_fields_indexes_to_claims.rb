class AddQaFieldsIndexesToClaims < ActiveRecord::Migration[7.0]
  def change
    add_index :claims, [:qa_required, :qa_completed_at], where: "(qa_required)"
  end
end
