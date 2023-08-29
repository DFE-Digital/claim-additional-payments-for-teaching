class UpdateSchoolWorkforceCensuses < ActiveRecord::Migration[7.0]
  def change
    remove_column :school_workforce_censuses, :subject_1, :string
    remove_column :school_workforce_censuses, :subject_2, :string
    remove_column :school_workforce_censuses, :subject_3, :string
    remove_column :school_workforce_censuses, :subject_4, :string
    remove_column :school_workforce_censuses, :subject_5, :string
    remove_column :school_workforce_censuses, :subject_6, :string
    remove_column :school_workforce_censuses, :subject_7, :string
    remove_column :school_workforce_censuses, :subject_8, :string
    remove_column :school_workforce_censuses, :subject_9, :string
    remove_column :school_workforce_censuses, :subject_10, :string
    remove_column :school_workforce_censuses, :subject_11, :string
    remove_column :school_workforce_censuses, :subject_12, :string
    remove_column :school_workforce_censuses, :subject_13, :string
    remove_column :school_workforce_censuses, :subject_14, :string
    remove_column :school_workforce_censuses, :subject_15, :string
    add_column :school_workforce_censuses, :urn, :string
    add_column :school_workforce_censuses, :contract_agreement_type, :string
    add_column :school_workforce_censuses, :totfte, :string
    add_column :school_workforce_censuses, :subject_description_sfr, :string
    add_column :school_workforce_censuses, :general_subject_code, :string
    add_column :school_workforce_censuses, :hours_taught, :string
  end
end
