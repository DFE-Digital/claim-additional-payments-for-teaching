require "csv"
require "excel_utils"

module Reports
  class DuplicateClaims
    include Admin::ClaimsHelper

    NAME = "Duplicate Approved Claims"
    HEADERS = [
      "Claim reference",
      "Teacher reference number",
      "Full name",
      "Policy name",
      "Claim amount",
      "Claim status",
      "Decision date",
      "Decision agent"
    ].freeze

    def initialize
      @claims = Claim.approved.select { |claim| Claim::MatchingAttributeFinder.new(claim).matching_claims.any? }
    end

    def to_csv
      CSV.generate(write_headers: true, headers: HEADERS) do |csv|
        @claims.each do |claim|
          csv << row(
            claim.reference,
            claim.eligibility.try(:teacher_reference_number),
            claim.full_name,
            claim.policy,
            claim.award_amount,
            status(claim),
            claim.latest_decision&.created_at,
            claim.latest_decision&.created_by&.full_name
          )
        end
      end
    end

    private

    def row(*entries)
      entries.map { |entry| ExcelUtils.escape_formulas(entry) }
    end
  end
end
