class BackFillDecisionsApprovedColumn < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      UPDATE decisions
      SET approved = CASE result
        WHEN 0 THEN TRUE
        WHEN 1 THEN FALSE
      END;
    SQL
  end

  def down
    execute <<-SQL
      UPDATE decisions
      SET approved = NULL;
    SQL
  end
end
