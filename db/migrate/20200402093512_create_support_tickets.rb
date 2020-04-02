class CreateSupportTickets < ActiveRecord::Migration[6.0]
  def change
    create_table :support_tickets, id: :uuid do |t|
      t.string :url, null: false
      t.references :claim, foreign_key: true, type: :uuid
      t.references :created_by, type: :uuid, foreign_key: {to_table: :dfe_sign_in_users}
      t.timestamps
    end
  end
end
