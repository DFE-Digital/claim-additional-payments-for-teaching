module DfeSignIn
  class UserDataImporterJob < ApplicationJob
    queue_as :user_data

    def perform
      return if Rails.env.review_app_like?

      Rails.logger.info "Importing DfE Sign-in user data..."

      DfeSignIn::User::USER_TYPES.each do |user_type|
        UserDataImporter.new(user_type:).run
      end
    end
  end
end
