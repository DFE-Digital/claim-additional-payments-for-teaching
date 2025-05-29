module DfeSignIn
  class SlackNotificationJob < ApplicationJob
    def perform(user_uuid)
      Rails.logger.info "Notifying Slack of new DfE Sign-in user #{user_uuid}..."
      SlackNotification.new(user_uuid).run
    end
  end
end
