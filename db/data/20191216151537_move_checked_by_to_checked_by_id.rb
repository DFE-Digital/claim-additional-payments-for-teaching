class MoveCheckedByToCheckedById < ActiveRecord::Migration[6.0]
  def up
    Check.all.each do |check|
      user_id = check.read_attribute(:checked_by)
      user = DfeSignIn::User.find_or_create_by(dfe_sign_in_id: user_id)
      check.update_column(:checked_by_id, user.id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
