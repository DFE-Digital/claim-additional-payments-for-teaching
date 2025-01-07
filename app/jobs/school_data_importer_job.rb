class SchoolDataImporterJob < ApplicationJob
  queue_as :school_data

  def perform
    Rails.logger.info "Importing school data..."
    SchoolDataImporter.new.run
  end
end
