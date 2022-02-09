class CreateSchoolWorkforceCensus < ActiveRecord::Migration[6.0]
  def change
    create_table :school_workforce_censuses, id: :uuid do |t|
      t.string :teacher_reference_number
      t.string :subject_1
      t.string :subject_2
      t.string :subject_3
      t.string :subject_4
      t.string :subject_5
      t.string :subject_6
      t.string :subject_7
      t.string :subject_8
      t.string :subject_9
      t.timestamps
    end
  end
end
