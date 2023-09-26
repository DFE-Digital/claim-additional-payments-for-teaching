class UpdateSchoolWorkforceCensuses < ActiveRecord::Migration[7.0]
  def change
    add_column :school_workforce_censuses, :school_urn, :integer
    add_column :school_workforce_censuses, :contract_agreement_type, :string
    add_column :school_workforce_censuses, :totfte, :float
    add_column :school_workforce_censuses, :subject_description_sfr, :string
    add_column :school_workforce_censuses, :general_subject_code, :string
    add_column :school_workforce_censuses, :hours_taught, :integer

    (1..15).each do |n|
      remove_column :school_workforce_censuses, "subject_#{n}".to_sym, :string
    end

    add_index :school_workforce_censuses, :teacher_reference_number
  end
end
