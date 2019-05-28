class AddLocalAuthorityDisctrictRefToSchools < ActiveRecord::Migration[5.2]
  def change
    add_reference :schools, :local_authority_district, foreign_key: true, type: :uuid
  end
end
