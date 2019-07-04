class SchoolDataImporterJob < CronJob
  self.cron_expression = "0 0 * * *"
  self.perform_on_schedule = true

  queue_as :school_data

  def perform
    Rails.logger.info "Importing school data..."
    SchoolDataImporter.new.run
  end
end
