require "csv"
require "excel_utils"

module Reports
  class FailedProviderCheckClaims
    include Admin::ClaimsHelper

    def self.provider_verification_label(field)
      I18n.t("further_education_payments.admin.task_questions.provider_verification.#{field}.label")
    end
    private_class_method :provider_verification_label

    NAME = "Claims with failed provider check"
    HEADERS = [
      "Claim reference",
      "Teacher reference number",
      "Full name",
      "Claim amount",
      "Claim status",
      "Decision date",
      "Decision agent",
      "Provider response: #{provider_verification_label("contract_type")}",
      "Provider response: #{provider_verification_label("teaching_responsibilities")}",
      "Provider response: #{provider_verification_label("further_education_teaching_start_year")}",
      "Provider response: #{provider_verification_label("teaching_hours_per_week")}",
      "Provider response: #{provider_verification_label("half_teaching_hours")}",
      "Provider response: #{provider_verification_label("subjects_taught")}",
      "Provider response: #{provider_verification_label("taught_at_least_one_term")}",
      "Provider response: #{provider_verification_label("teaching_hours_per_week_next_term")}"
    ].freeze

    def initialize
      @claims = Claim.includes(:tasks)
        .where(eligibility_type: "Policies::FurtherEducationPayments::Eligibility", tasks: {name: "provider_verification", passed: false})
        .approved
    end

    def to_csv
      CSV.generate(write_headers: true, headers: HEADERS) do |csv|
        @claims.each do |claim|
          csv << row(
            claim.reference,
            claim.eligibility.teacher_reference_number,
            claim.full_name,
            claim.award_amount,
            status(claim),
            claim.latest_decision.created_at,
            claim.latest_decision.created_by.full_name,
            verification_assertion(claim, "contract_type"),
            verification_assertion(claim, "teaching_responsibilities"),
            verification_assertion(claim, "further_education_teaching_start_year"),
            verification_assertion(claim, "teaching_hours_per_week"),
            verification_assertion(claim, "half_teaching_hours"),
            verification_assertion(claim, "subjects_taught"),
            verification_assertion(claim, "taught_at_least_one_term"),
            verification_assertion(claim, "teaching_hours_per_week_next_term")
          )
        end
      end
    end

    private

    def row(*entries)
      entries.map { |entry| ExcelUtils.escape_formulas(entry) }
    end

    def verification_assertion(claim, name)
      claim.eligibility["assertions"].find { |assertion| assertion["name"] == name }["outcome"]
    end
  end
end
