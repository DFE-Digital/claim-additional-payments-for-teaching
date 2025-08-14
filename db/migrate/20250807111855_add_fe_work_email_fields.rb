class AddFeWorkEmailFields < ActiveRecord::Migration[8.0]
  def change
    add_column :further_education_payments_eligibilities,
      :work_email,
      :citext

    add_column :further_education_payments_eligibilities,
      :work_email_verified,
      :boolean
  end
end
