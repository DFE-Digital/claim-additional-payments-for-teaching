class StudentLoansDataImporter < CsvImporter::Base
  import_options(
    target_data_model: StudentLoansData,
    transform_rows_with: :row_to_hash,
    skip_row_if: :skip_row_conditions?,
    mandatory_headers: [
      "Claim reference",
      "NINO",
      "Full name",
      "Date of birth",
      "Policy name",
      "No of Plans Currently Repaying",
      "Plan Type of Deduction",
      "Amount"
    ]
  )

  private

  def skip_row_conditions?(row)
    row.fetch("NINO").blank?
  end

  def row_to_hash(row)
    {
      claim_reference: row.fetch("Claim reference"),
      nino: row.fetch("NINO"),
      full_name: row.fetch("Full name"),
      date_of_birth: date_of_birth(row.fetch("Date of birth")),
      policy_name: row.fetch("Policy name"),
      no_of_plans_currently_repaying: row.fetch("No of Plans Currently Repaying"),
      plan_type_of_deduction: row.fetch("Plan Type of Deduction"),
      amount: row.fetch("Amount")
    }
  end

  def date_of_birth(dob_str)
    return unless dob_str.present?

    Date.strptime(dob_str, "%m/%d/%Y")
  rescue Date::Error
    nil
  end
end
