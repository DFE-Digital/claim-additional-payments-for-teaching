class ImportCensusJob < FileImporterJob
  import_with SchoolWorkforceCensusDataImporter
  rescue_with -> do
    SchoolWorkforceCensus.delete_all
    AnalyticsImporter.import(SchoolWorkforceCensus)
  end
  notify_with AdminMailer, success: :census_csv_processing_success, failure: :census_csv_processing_error
end
