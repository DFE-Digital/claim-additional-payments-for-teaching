# rubocop:disable Rails/ThreeStateBooleanColumn
class CreateForm < ActiveRecord::Migration[7.0]
  def change
    create_table :forms do |t|
      t.string :given_name
      t.string :middle_name
      t.string :family_name
      t.string :email_address
      t.string :phone_number
      t.date :date_of_birth
      t.string :nationality
      t.string :sex
      t.string :passport_number
      t.string :subject
      t.string :visa_type
      t.date :date_of_entry
      t.date :start_date
      t.string :address_line_1
      t.string :address_line_2
      t.string :city
      t.string :postcode
      t.string :application_route
      t.boolean :state_funded_secondary_school
      t.boolean :one_year
      t.string :school_name
      t.string :school_headteacher_name
      t.string :school_address_line_1
      t.string :school_address_line_2
      t.string :school_city
      t.string :school_postcode

      t.timestamps
    end
  end
end
# rubocop:enable Rails/ThreeStateBooleanColumn
