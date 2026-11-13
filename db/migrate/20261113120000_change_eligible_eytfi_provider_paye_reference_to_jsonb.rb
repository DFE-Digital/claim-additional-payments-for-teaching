class ChangeEligibleEytfiProviderPayeReferenceToJsonb < ActiveRecord::Migration[8.1]
  def up
    change_column(
      :eligible_eytfi_providers,
      :paye_reference,
      :jsonb,
      using: "CASE WHEN paye_reference IS NULL OR btrim(paye_reference) IN ('', 'n/a') THEN '[]'::jsonb ELSE jsonb_build_array(paye_reference) END",
      default: [],
      null: false
    )
  end

  def down
    add_column :eligible_eytfi_providers, :legacy_paye_reference, :text
    execute <<~SQL
      UPDATE eligible_eytfi_providers
      SET legacy_paye_reference = (
        SELECT string_agg(reference, chr(10) ORDER BY position)
        FROM jsonb_array_elements_text(paye_reference) WITH ORDINALITY AS refs(reference, position)
      )
    SQL
    remove_column :eligible_eytfi_providers, :paye_reference
    rename_column :eligible_eytfi_providers, :legacy_paye_reference, :paye_reference
  end
end
