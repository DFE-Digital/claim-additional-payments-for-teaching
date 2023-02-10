require "csv"

class Claim
  # Used to genearte a CSV of claims that includes: Claim reference, teacher
  # reference number, and full name. These are sent to various other parts of
  # DfE when requesting data for teachers that have made a claim.
  class DataReportRequest
    HEADERS = [
      "Claim reference",
      "Teacher reference number",
      "NINO",
      "Full name",
      "Email",
      "Date of birth",
      "ITT subject",
      "Policy name",
      "School name",
      "School unique reference number"
    ].freeze

    def initialize(claims)
      @claims = claims
    end

    def to_csv
      CSV.generate(write_headers: true, headers: HEADERS) do |csv|
        @claims.each do |claim|
          csv << [
            claim.reference,
            claim.teacher_reference_number,
            claim.national_insurance_number,
            claim.full_name,
            claim.email_address,
            claim.date_of_birth,
            claim.eligibility.eligible_itt_subject,
            claim.policy,
            claim.eligibility.current_school.name,
            claim.eligibility.current_school.urn
          ]
        end
      end
    end
  end
end
