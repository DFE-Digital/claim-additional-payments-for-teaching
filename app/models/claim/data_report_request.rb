require "csv"
require "excel_utils"

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
          csv << Serializers.const_get(claim.policy.to_s).new(claim:).to_csv_row
        end
      end
    end

    module Serializers
      class Base
        attr_reader :claim

        def initialize(claim:)
          @claim = claim
        end
      end

      class LevellingUpPremiumPayments < Base
        def to_csv_row
          [
            ExcelUtils.escape_formulas(claim.reference),
            ExcelUtils.escape_formulas(claim.eligibility.teacher_reference_number),
            ExcelUtils.escape_formulas(claim.national_insurance_number),
            ExcelUtils.escape_formulas(claim.full_name),
            ExcelUtils.escape_formulas(claim.email_address),
            ExcelUtils.escape_formulas(claim.date_of_birth),
            ExcelUtils.escape_formulas(claim.eligibility.eligible_itt_subject),
            ExcelUtils.escape_formulas(claim.policy),
            ExcelUtils.escape_formulas(claim.eligibility.current_school.name),
            ExcelUtils.escape_formulas(claim.eligibility.current_school.urn)
          ]
        end
      end

      class StudentLoans < LevellingUpPremiumPayments
      end

      class EarlyCareerPayments < LevellingUpPremiumPayments
      end

      class FurtherEducationPayments < Base
        def to_csv_row
          [
            ExcelUtils.escape_formulas(claim.reference),
            ExcelUtils.escape_formulas(claim.eligibility.teacher_reference_number),
            ExcelUtils.escape_formulas(claim.national_insurance_number),
            ExcelUtils.escape_formulas(claim.full_name),
            ExcelUtils.escape_formulas(claim.email_address),
            ExcelUtils.escape_formulas(claim.date_of_birth),
            ExcelUtils.escape_formulas(nil),
            ExcelUtils.escape_formulas(claim.policy),
            ExcelUtils.escape_formulas(claim.eligibility.school.name),
            ExcelUtils.escape_formulas(claim.eligibility.school.urn)
          ]
        end
      end
    end
  end
end
