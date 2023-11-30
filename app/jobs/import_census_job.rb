class ImportCensusJob < FileImporterJob
  import_with SchoolWorkforceCensusDataImporter
  rescue_with -> { SchoolWorkforceCensus.delete_all }
  notify_with AdminMailer, success: :census_csv_processing_success, failure: :census_csv_processing_error
end
