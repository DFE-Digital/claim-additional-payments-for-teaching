module Admin
  class PageController < BaseAdminController
    before_action :ensure_service_team

    def index
    end
  end
end
