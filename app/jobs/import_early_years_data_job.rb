class ImportEarlyYearsDataJob < FileImporterJob
  import_with EarlyYearsDataImporter do
    Rails.logger.info "EY data imported"
  end
  rescue_with -> { EarlyYearsData.delete_all }
end
