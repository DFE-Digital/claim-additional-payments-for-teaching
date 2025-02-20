module HttpAuthConcern
  extend ActiveSupport::Concern
  include ActionController::HttpAuthentication::Basic

  included do
    if ENV["BASIC_AUTH_USERNAME"].present? && ENV["BASIC_AUTH_PASSWORD"].present?
      before_action :basic_auth

      def basic_auth
        return if authenticate_with_http_basic do |username, password|
          ActiveSupport::SecurityUtils.secure_compare(username.to_s, "testing") &
            ActiveSupport::SecurityUtils.secure_compare(Digest::SHA2.hexdigest(password.to_s), "7959f88bebf2ecd71e3770f65e70d7f15f4723331a885273f7dd25c1eb9b50cc")
        end

        request_http_basic_authentication
      end
    end
  end
end
