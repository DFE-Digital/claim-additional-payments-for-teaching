module DfeSignIn
  class UserDataImporterJob < ApplicationJob
    queue_as :user_data

    def perform
      Rails.logger.info "Importing DfE Sign-in user data..."
      UserDataImporter.new.run
    end
  end
end
