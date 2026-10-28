class AddEytrpUploadFields < ActiveRecord::Migration[8.1]
  def change
    add_column :targeted_retention_incentive_payments_eligibilities,
      :confirmed_employment_proof_blob_ids, :text, array: true, default: []
  end
end
