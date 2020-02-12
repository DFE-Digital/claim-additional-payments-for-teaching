class DataMigrationGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def copy_data_migration_file
    @file_name = filename_with_timestamp
    template "data_migration.template", "db/data/#{@file_name}"
  end

  def filename_with_timestamp
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
    "#{timestamp}_#{file_name.underscore}.rb"
  end
end
