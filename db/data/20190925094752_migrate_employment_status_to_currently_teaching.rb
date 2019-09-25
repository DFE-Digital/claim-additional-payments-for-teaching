class MigrateEmploymentStatusToCurrentlyTeaching < ActiveRecord::Migration[5.2]
  def up
    StudentLoans::Eligibility.where.not(employment_status: nil).each do |claim|
      # Value `2` was `:no_school`.
      if claim.employment_status_before_type_cast == 2
        claim.update!(currently_teaching: false, employment_status: nil)
      else
        claim.update!(currently_teaching: true)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
