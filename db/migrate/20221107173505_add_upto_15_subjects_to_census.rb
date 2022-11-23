class AddUpto15SubjectsToCensus < ActiveRecord::Migration[6.1]
  def change
    add_column :school_workforce_censuses, :subject_10, :string
    add_column :school_workforce_censuses, :subject_11, :string
    add_column :school_workforce_censuses, :subject_12, :string
    add_column :school_workforce_censuses, :subject_13, :string
    add_column :school_workforce_censuses, :subject_14, :string
    add_column :school_workforce_censuses, :subject_15, :string
  end
end
