module Admin
  class PageController < BaseAdminController
    before_action :ensure_service_team

    def index
      flash[:notice] = "There is currently no school workforce data present" if SchoolWorkforceCensus.all.size.zero?
    end
  end
end
