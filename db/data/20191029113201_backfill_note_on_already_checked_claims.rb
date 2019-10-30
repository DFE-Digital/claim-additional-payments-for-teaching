class BackfillNoteOnAlreadyCheckedClaims < ActiveRecord::Migration[5.2]
  def up
    return unless ENV["NOTES_TO_BACKFILL"]

    rows = ENV["NOTES_TO_BACKFILL"].split("|")

    rows.each do |row|
      row = row.split(",")
      claim = Claim.find_by_reference(row[0])

      next if claim.nil? || claim.check.nil?

      claim.check.update_column(:notes, row[1])
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
