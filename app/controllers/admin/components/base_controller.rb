module Admin
  module Components
    class BaseController < BaseAdminController
      before_action :ensure_service_operator
      before_action -> { raise ActiveRecord::RecordNotFound if Rails.env.production? && !Rails.env.review_app_like? }
    end
  end
end
