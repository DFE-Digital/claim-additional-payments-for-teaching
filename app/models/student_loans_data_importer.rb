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
    row.fetch("NINO").blank? || cast_as_date(row.fetch("Date of birth")).nil?
  end

  def row_to_hash(row)
    {
      claim_reference: row.fetch("Claim reference"),
      nino: row.fetch("NINO"),
      full_name: row.fetch("Full name"),
      date_of_birth: cast_as_date(row.fetch("Date of birth")),
      policy_name: row.fetch("Policy name"),
      no_of_plans_currently_repaying: calculate_no_of_plans_currently_repaying(row.fetch("No of Plans Currently Repaying")),
      plan_type_of_deduction: calculate_plan_type_of_deduction(row.fetch("Plan Type of Deduction")),
      amount: row.fetch("Amount")
    }
  end

  def calculate_plan_type_of_deduction(value)
    if value == "No data"
      nil
    else
      value
    end
  end

  def calculate_no_of_plans_currently_repaying(value)
    if value == "No data"
      nil
    else
      value
    end
  end

  def cast_as_date(string)
    Date.strptime(string, I18n.t("date.formats.day_month_year"))
  rescue TypeError, Date::Error
    nil
  end
end
