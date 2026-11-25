class CreateAdminPermissionsGrants < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_permissions_grants, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: {to_table: :dfe_sign_in_users}
      t.string :permission, null: false

      # Nullable so grants/revocations made by the system (eg a backfill) can
      # be recorded without an acting user
      t.references :granted_by, type: :uuid, foreign_key: {to_table: :dfe_sign_in_users}
      t.datetime :granted_at, null: false
      t.references :revoked_by, type: :uuid, foreign_key: {to_table: :dfe_sign_in_users}
      t.datetime :revoked_at

      t.timestamps
    end

    # A user can hold at most one active grant for a given permission.
    # Re-granting a revoked permission inserts a new row, preserving history.
    add_index :admin_permissions_grants,
      [:user_id, :permission],
      unique: true,
      where: "revoked_at IS NULL",
      name: "index_admin_permissions_grants_active_uniqueness"
  end
end
