claims = Claim
  .by_policy(Policies::EarlyYearsTeachersFinancialIncentivePayments)
  .by_academic_year(AcademicYear.new(2026))

# ~300 claims
claims.each do |claim|
  dqt_note = claim.notes.by_label("qualifications").detect do |note|
    note.body.include? "[DQT Qualifications]"
  end

  check = AutomatedChecks::ClaimVerifiers::EyQualificationCheck.new(claim: claim)

  body = check.send(:note_body)

  note_created = dqt_note.created_at

  label = dqt_note.label

  ApplicationRecord.transaction do
    dqt_note&.destroy!

    claim.notes.create!(
      body: body,
      label: label,
      created_at: note_created
    )
  end
end
