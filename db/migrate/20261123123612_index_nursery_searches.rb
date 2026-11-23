class IndexNurserySearches < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    enable_extension "pg_trgm"

    execute <<~SQL
      CREATE INDEX CONCURRENTLY index_eytfi_providers_on_sanitised_name_trgm
      ON eligible_eytfi_providers
      USING gin ((sanitised_name::text) gin_trgm_ops);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX CONCURRENTLY IF EXISTS
        index_eytfi_providers_on_sanitised_name_trgm;
    SQL
  end
end
