class AddFlaggedAsMismatchOnTeachingStartYearToFeEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column :further_education_payments_eligibilities,
      :flagged_as_mismatch_on_teaching_start_year,
      :boolean,
      default: false
  end
end
