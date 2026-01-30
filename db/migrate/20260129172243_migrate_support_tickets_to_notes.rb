class MigrateSupportTicketsToNotes < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      INSERT INTO notes (id, body, claim_id, created_by_id, created_at, updated_at)
      SELECT
        gen_random_uuid(),
        'ZenDesk ticket: ' || url,
        claim_id,
        created_by_id,
        created_at,
        updated_at
      FROM support_tickets
    SQL

    drop_table :support_tickets
  end

  def down
    create_table :support_tickets, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :claim_id
      t.uuid :created_by_id
      t.string :url, null: false
      t.timestamps
    end

    add_index :support_tickets, :claim_id
    add_index :support_tickets, :created_by_id

    add_foreign_key :support_tickets, :claims
    add_foreign_key :support_tickets, :dfe_sign_in_users, column: :created_by_id

    execute <<-SQL
      INSERT INTO support_tickets (id, url, claim_id, created_by_id, created_at, updated_at)
      SELECT
        gen_random_uuid(),
        SUBSTRING(body FROM 17),
        claim_id,
        created_by_id,
        created_at,
        updated_at
      FROM notes
      WHERE body LIKE 'ZenDesk ticket: %'
    SQL

    execute <<-SQL
      DELETE FROM notes WHERE body LIKE 'ZenDesk ticket: %'
    SQL
  end
end
