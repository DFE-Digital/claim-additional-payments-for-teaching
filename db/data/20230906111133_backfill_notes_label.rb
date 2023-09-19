# Run me with `rails runner db/data/20230906111133_backfill_notes_label.rb`

identity_confirmation_notes = 0
qualifications_notes = 0
census_subjects_taught_notes = 0
employment_notes = 0
induction_confirmation_notes = 0
skipped_notes = 0

unlabelled_notes = Note.where(created_by_id: nil).where(label: nil)

puts "Processing #{unlabelled_notes.count} notes without author and label..."

unlabelled_notes.each do |note|
  if note.body.include?("[DQT Identity]") || note.body =~ %r{National Insurance|Teacher reference|First name or surname|Date of birth|Not matched}
    note.update!(label: "identity_confirmation")
    identity_confirmation_notes += 1
  elsif note.body.include?("[DQT Qualification]") || note.body.include?("ITT subject codes:")
    note.update!(label: "qualifications")
    qualifications_notes += 1
  elsif note.body.include?("[School Workforce Census]")
    note.update!(label: "census_subjects_taught")
    census_subjects_taught_notes += 1
  elsif note.body.include?("[Employment]")
    note.update!(label: "employment")
    employment_notes += 1
  elsif note.body.include?("[DQT Induction]")
    note.update!(label: "induction_confirmation")
    induction_confirmation_notes += 1
  else
    skipped_notes += 1
  end
end

puts "Backfilling summary"
puts "----------------------------------------"
puts "Identity confirmation notes:  #{identity_confirmation_notes}"
puts "Qualification notes:          #{qualifications_notes}"
puts "Census subjects taught notes: #{census_subjects_taught_notes}"
puts "Employment notes:             #{employment_notes}"
puts "Induction confirmation notes: #{induction_confirmation_notes}"
puts "Skipped notes:                #{skipped_notes}"
puts "----------------------------------------"
