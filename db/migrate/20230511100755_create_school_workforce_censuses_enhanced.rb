class CreateSchoolWorkforceCensusesEnhanced < ActiveRecord::Migration[7.0]
  def change
    create_table :school_workforce_censuses_enhanced, id: :uuid do |t|
      t.integer :census_year
      t.string :trn
      t.integer :school_urn
      t.string :contract_type
      t.decimal :fte
      t.boolean :full_time
      t.string :subject
      t.timestamps
    end

    add_index :school_workforce_censuses_enhanced, [:census_year, :trn, :school_urn, :contract_type, :fte, :full_time, :subject], unique: true, name: :swc_unique
    add_index :school_workforce_censuses_enhanced, :trn
    add_index :school_workforce_censuses_enhanced, :school_urn
  end
end
