class AddRedactedAttributesToStudentLoansEligibilities < ActiveRecord::Migration[8.1]
  def change
    add_column(
      :student_loans_eligibilities,
      :redacted_attributes,
      :jsonb,
      default: {}
    )
  end
end
