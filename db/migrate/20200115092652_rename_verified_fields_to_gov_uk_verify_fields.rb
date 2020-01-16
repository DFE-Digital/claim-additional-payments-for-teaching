class RenameVerifiedFieldsToGovUkVerifyFields < ActiveRecord::Migration[6.0]
  def change
    rename_column :claims, :verified_fields, :govuk_verify_fields
  end
end
