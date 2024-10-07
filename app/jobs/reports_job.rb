class ReportsJob < CronJob
  self.cron_expression = "0 6 * * 2#2" # second Tuesday of the month

  def perform
    Rails.logger.info "Generating Ops reports"

    csv = Reports::DuplicateClaims.new.to_csv
    Report.create!(name: Reports::DuplicateClaims::NAME, csv: csv, number_of_rows: csv.lines.count - 1)
    csv = Reports::FailedQualificationClaims.new.to_csv
    Report.create!(name: Reports::FailedQualificationClaims::NAME, csv: csv, number_of_rows: csv.lines.count - 1)
    csv = Reports::FailedProviderCheckClaims.new.to_csv
    Report.create!(name: Reports::FailedProviderCheckClaims::NAME, csv: csv, number_of_rows: csv.lines.count - 1)
  end
end
