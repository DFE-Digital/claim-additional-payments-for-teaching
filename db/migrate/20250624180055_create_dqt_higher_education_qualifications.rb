class CreateDqtHigherEducationQualifications < ActiveRecord::Migration[8.0]
  def change
    create_table :dqt_higher_education_qualifications, id: :uuid do |t|
      t.string :teacher_reference_number, limit: 11, null: false
      t.date :date_of_birth, null: false
      t.string :national_insurance_number, limit: 9
      t.string :subject_code, null: false
      t.string :description

      t.timestamps
    end

    add_index :dqt_higher_education_qualifications, [:teacher_reference_number, :date_of_birth]
    add_index :dqt_higher_education_qualifications, [:teacher_reference_number, :date_of_birth, :subject_code], unique: true
  end
end
