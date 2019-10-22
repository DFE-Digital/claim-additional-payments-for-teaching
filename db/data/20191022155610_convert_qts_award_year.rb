class ConvertQtsAwardYear < ActiveRecord::Migration[5.2]
  def up
    StudentLoans::Eligibility.where("qts_award_year > 0").each do |eligibility|
      eligibility.update_attribute(:qts_award_year, 1)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
