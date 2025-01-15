require "rails_helper"

RSpec.describe Reports::DuplicateClaims do
  it "returns a csv of duplciate claims" do
    claim_1 = create(
      :claim,
      :approved,
      academic_year: AcademicYear.current,
      email_address: "test@example.com"
    )

    create(
      :claim,
      email_address: "test@example.com",
      academic_year: AcademicYear.current
    )

    csv = CSV.parse(described_class.new.to_csv, headers: true)

    expect(csv.to_a).to match_array([
      [
        "Claim reference",
        "Teacher reference number",
        "Full name",
        "Policy name",
        "Claim amount",
        "Claim status",
        "Decision date",
        "Decision agent"
      ],
      [
        claim_1.reference,
        claim_1.eligibility.teacher_reference_number,
        claim_1.full_name,
        claim_1.policy.to_s,
        claim_1.award_amount.to_s,
        "Approved awaiting payroll",
        claim_1.latest_decision.created_at.to_s,
        claim_1.latest_decision.created_by.full_name
      ]
    ])
  end
end
