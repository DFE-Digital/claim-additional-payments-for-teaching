class RemoveGovukVerifyFields < ActiveRecord::Migration[8.1]
  def change
    remove_column :claims, :govuk_verify_fields, :array, default: []
  end
end
