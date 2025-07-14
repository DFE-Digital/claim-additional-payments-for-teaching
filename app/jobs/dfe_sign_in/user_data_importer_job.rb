module DfeSignIn
  class UserDataImporterJob < ApplicationJob
    queue_as :user_data

    def perform
      return if ENV["ENVIRONMENT_NAME"].start_with?("review")

      Rails.logger.info "Importing DfE Sign-in user data..."
      UserDataImporter.new.run
    end
  end
end
