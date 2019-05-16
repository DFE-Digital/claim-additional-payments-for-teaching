class AddTeacherReferenceNumberToTslrClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :teacher_reference_number, :string, limit: 11
  end
end
