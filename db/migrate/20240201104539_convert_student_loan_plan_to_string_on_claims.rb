class ConvertStudentLoanPlanToStringOnClaims < ActiveRecord::Migration[7.0]
  def up
    change_column :claims, :student_loan_plan,
      "varchar USING (#{using_case_statement(:student_loan_plan, STUDENT_LOAN_PLAN_ENUM, :integer_to_varchar)})"
  end

  def down
    change_column :claims, :student_loan_plan,
      "integer USING (#{using_case_statement(:student_loan_plan, STUDENT_LOAN_PLAN_ENUM, :varchar_to_integer)})"
  end

  # The values below are from Claim::STUDENT_LOAN_PLAN_OPTIONS on Thu, 01 Feb 2024 12:24:14.097659000 GMT +00:00
  STUDENT_LOAN_PLAN_ENUM =
    {
      plan_1: 0,
      plan_2: 1,
      plan_3: 2,
      plan_4: 3,
      plan_1_and_2: 4,
      plan_1_and_3: 5,
      plan_1_and_2_and_3: 6,
      plan_1_and_4: 7,
      plan_2_and_3: 8,
      plan_2_and_4: 9,
      plan_3_and_4: 10,
      plan_4_and_3: 11,
      not_applicable: 12
    }

  def using_case_statement(column_name, enum_hash, conversion_type)
    enum_hash.reduce(["CASE #{column_name}"]) do |acc, (str, i)|
      if conversion_type == :integer_to_varchar
        acc.push("WHEN #{i} THEN '#{str}'")
      elsif conversion_type == :varchar_to_integer
        acc.push("WHEN '#{str}' THEN #{i}")
      end
    end&.push("END")&.join(" ")
  end
end
