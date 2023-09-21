class UpdateSchoolWorkforceCensuses < ActiveRecord::Migration[7.0]
  def change
    add_columns_if_not_exist(
      :school_workforce_censuses,
      {
        school_urn: :integer,
        contract_agreement_type: :string,
        totfte: :integer,
        subject_description_sfr: :string,
        general_subject_code: :string,
        hours_taught: :integer
      }
    )

    (1..15).each do |n|
      add_column_if_not_exist(
        :school_workforce_censuses,
        "subject_#{n}".to_sym,
        :string
      )
    end

    add_index_if_not_exist(
      :school_workforce_censuses,
      :teacher_reference_number
    )
  end

  private

  def add_column_if_not_exist(table, column, type)
    add_column table, column, type unless column_exists?(table, column)
  end

  def add_columns_if_not_exist(table, columns)
    columns.each { |column, type| add_column_if_not_exist(table, column, type) }
  end

  def add_index_if_not_exist(table, column)
    add_index table, column unless index_exists?(table, column)
  end
end
