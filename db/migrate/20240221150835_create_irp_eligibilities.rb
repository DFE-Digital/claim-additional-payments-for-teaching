class CreateIrpEligibilities < ActiveRecord::Migration[7.0]
  def change
    create_table :irp_eligibilities, id: :uuid do |t|
      t.boolean :one_year
      t.boolean :state_funded_secondary_school
      t.date :date_of_entry
      t.date :start_date
      t.string :application_route
      t.string :ip_address
      t.string :nationality
      t.string :passport_number
      t.string :school_headteacher_name
      t.string :school_name
      t.string :school_address_line_1
      t.string :school_address_line_2
      t.string :school_city
      t.string :school_postcode
      t.string :subject
      t.string :visa_type

      t.timestamps
    end
  end
end
