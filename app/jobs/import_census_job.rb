class ImportCensusJob < FileImporterJob
  import_with SchoolWorkforceCensusDataImporter
  rescue_with -> do
    SchoolWorkforceCensus.delete_all
    Rake::Task["dfe:analytics:import_entity"].invoke(SchoolWorkforceCensus.table_name) if DfE::Analytics.enabled?
  end
  notify_with AdminMailer, success: :census_csv_processing_success, failure: :census_csv_processing_error
end
