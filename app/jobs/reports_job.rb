class ReportsJob < ApplicationJob
  def perform
    Rails.logger.info "Generating Ops reports"

    csv = Reports::FailedQualificationClaims.new.to_csv

    Report
      .find_or_initialize_by(name: Reports::FailedQualificationClaims::NAME)
      .update!(csv: csv, number_of_rows: csv.lines.count - 1)

    csv = Reports::FailedProviderCheckClaims.new.to_csv

    Report
      .find_or_initialize_by(name: Reports::FailedProviderCheckClaims::NAME)
      .update!(csv: csv, number_of_rows: csv.lines.count - 1)

    csv = Reports::DuplicateClaims.new.to_csv

    Report
      .find_or_initialize_by(name: Reports::DuplicateClaims::NAME)
      .update!(csv: csv, number_of_rows: csv.lines.count - 1)
  end
end
