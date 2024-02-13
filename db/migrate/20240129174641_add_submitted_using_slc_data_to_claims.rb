class AddSubmittedUsingSlcDataToClaims < ActiveRecord::Migration[7.0]
  def up
    add_column :claims, :submitted_using_slc_data, :boolean, default: false

    # For claims submitted until now, set the value to `null` (undetermined).
    # This value will help "virtually" mark the cutover date – when the student
    # loan questions are removed from all active journeys.
    execute("UPDATE claims SET submitted_using_slc_data = null")
  end

  def down
    drop_column :claims, :submitted_using_slc_data
  end
end
