module DfeSignIn
  class UserDataImporterJob < CronJob
    self.cron_expression = "0 2 * * *"

    queue_as :user_data

    def perform
      Rails.logger.info "Importing DfE Sign-in user data..."
      UserDataImporter.new.run
    end
  end
end
