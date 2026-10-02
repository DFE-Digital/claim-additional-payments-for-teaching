require "csv"

output_path = "./fe-provider-amendments.csv"

headers = [
  "provider_ukprn",
  "provider_name",
  "claim_reference",
  "amendment_created_at",
  "amendment_notes",
  "amendment_changes",
]

amendments = Amendment
  .joins(:claim)
  .where(
    claim: {
      policy: Policies::FurtherEducationPayments,
      academic_year: AcademicYear.new(2025)
    }
  )
  .where.not(
    notes: "Student loan details updated from SLC data"
  )

CSV.open(output_path, "w", headers:, write_headers: true) do |csv|
  amendments.find_each do |amendment|
    csv << [
      amendment.claim.school.ukprn,
      amendment.claim.school.name,
      amendment.claim.reference,
      amendment.created_at,
      amendment.notes,
      amendment.claim_changes,
    ]
  end
end

output_path = "./fe-provider-decisions.csv"

headers = [
  "provider_ukprn",
  "provider_name",
  "claim_reference",
  "approved",
  "undone",
  "decision_created_at",
  "decision_notes",
  "rejected_reasons",
]

decisions = Decision
  .joins(:claim)
  .where(
    claim: {
      policy: Policies::FurtherEducationPayments,
      academic_year: AcademicYear.new(2025)
    }
  )
  .where.not(
    notes: "Auto-approved"
  )
  .where(
    approved: false,
  )

CSV.open(output_path, "w", headers:, write_headers: true) do |csv|
  decisions.find_each do |decision|
    csv << [
      decision.claim.school.ukprn,
      decision.claim.school.name,
      decision.claim.reference,
      decision.approved,
      decision.undone,
      decision.created_at,
      decision.notes,
      decision.rejected_reasons,
    ]
  end
end

