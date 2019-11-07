class CreatePolicyConfigurationRecords < ActiveRecord::Migration[5.2]
  def up
    PolicyConfiguration.create!(policy_type: StudentLoans)
    PolicyConfiguration.create!(policy_type: MathsAndPhysics)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
