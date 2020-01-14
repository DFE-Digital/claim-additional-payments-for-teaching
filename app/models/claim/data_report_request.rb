require "csv"

class Claim
  # Used to genearte a CSV of claims that includes: Claim reference, teacher
  # reference number, and full name. These are sent to various other parts of
  # DfE when requesting data for teachers that have made a claim.
  class DataReportRequest
    HEADERS = [
      "Claim reference",
      "Teacher reference number",
      "Full name",
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
            claim.full_name,
          ]
        end
      end
    end
  end
end
